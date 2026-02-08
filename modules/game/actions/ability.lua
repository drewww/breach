local Item = prism.targets.InventoryTarget()

--- Accumulates damage and push for a position into tables (does not apply effects)
local function accumulateEffects(level, owner, pos, effect, crit, impact, damage, crits, push)
   local actors = level:query():at(pos:decompose()):gather()

   for _, actor in ipairs(actors) do
      if effect.push and effect.push > 0 then
         local vector = actor:getPosition() - owner:getPosition()
         if effect.pushFromCenter then
            vector = actor:getPosition() - impact
         end

         local amount = crit and effect.push * 2 or effect.push

         if not push[actor] then
            push[actor] = { amount = 0, vector = vector:normalize() }
         end
         push[actor].amount = push[actor].amount + amount
      end

      if effect.health then
         local pellet = crit and effect.health * 2 or effect.health
         damage[actor] = (damage[actor] or 0) + pellet
         if crit then crits[actor] = true end
      end
   end
end

--- Applies accumulated push and damage to all actors
local function applyEffects(level, owner, damage, crits, push)
   -- Apply pushes first (may cause collision damage)
   for actor, data in pairs(push) do
      local action = prism.actions.Push(owner, actor, data.vector, data.amount, true)
      level:tryPerform(action)

      if action.collision then
         damage[actor] = (damage[actor] or 0) + COLLISION_DAMAGE
      end
   end

   -- Then apply damage
   for actor, total in pairs(damage) do
      level:tryPerform(prism.actions.Damage(owner, actor, total, crits[actor] or false))
   end
end

--- Applies conditions to actors with ConditionHolder at a position
local function applyConditions(level, pos, effect)
   if not effect.condition then return end

   local actors = level:query(prism.components.ConditionHolder):at(pos:decompose()):iter()

   for actor, holder in actors do
      local condition = effect.condition:deepcopy()
      holder:add(condition)
      prism.logger.info("APPLY CONDITION ", condition)
   end
end

--- Applies non-damage effects at a position (spawn actors, explosions)
local function applySpawnEffects(level, item, pos, effect)
   local animate = item:get(prism.components.Animate)
   local spawned = nil

   if effect.spawnActor then
      if effect.actorOptions then
         spawned = prism.actors[effect.spawnActor](unpack(effect.actorOptions))
      else
         spawned = prism.actors[effect.spawnActor]()
      end
      level:addActor(spawned, pos:decompose())
   end

   if animate and animate.explode then
      level:yield(prism.messages.AnimationMessage({
         animation = spectrum.animations.Explosion(pos, 0.2 * animate.radius + 0.1, prism.Color4.YELLOW),
         actor = spawned,
         blocking = false,
         skippable = false
      }))
   end
end

--- Applies effects at a single position (for non-multishot weapons)
local function applyAtPosition(level, owner, item, pos, effect, crit, impact)
   local actors = level:query():at(pos:decompose()):gather()

   for _, actor in ipairs(actors) do
      local collision = 0

      if effect.push then
         local vector = actor:getPosition() - owner:getPosition()
         if effect.pushFromCenter then
            vector = actor:getPosition() - impact
         end

         local amount = crit and effect.push * 2 or effect.push
         local action = prism.actions.Push(owner, actor, vector:normalize(), amount, true)
         level:tryPerform(action)

         if action.collision then
            collision = COLLISION_DAMAGE
         end
      end

      if effect.health then
         local final = effect.health + collision
         if crit then final = final * 2 end
         level:tryPerform(prism.actions.Damage(owner, actor, final, crit))
      end
   end

   applyConditions(level, pos, effect)
   applySpawnEffects(level, item, pos, effect)
end

-- Currently this is in world positions.
-- TODO change it to be relative position so we can re-use it for
-- NPC intents.
local Direction = prism.Target():isVector2()

---@class ItemAbility : Action
local ItemAbility = prism.Action:extend("ItemAbility")

ItemAbility.targets = { Item, Direction }

function ItemAbility:canPerform(level, item, direction)
   -- Check the constraint components on the item: range, cost, cooldown.
   -- NOTE: 'target' represents the actual aim point (e.g., the enemy position).
   -- For line templates, the visual effect will extend beyond this to template.range.
   -- local rangeLegal, canSeeTarget, canPathStraightTo = self:canTarget(level)

   local costLegal, cooldownLegal = self:canFire(level)
   local _, _, _, seesPlayerIfNecessary = self:canTarget(level)
   local err = string.format("cost: %s cooldown: %s seesPlayerIfNecessary: %s", tostring(costLegal),
      tostring(cooldownLegal), tostring(seesPlayerIfNecessary))

   prism.logger.info("ability canPerform: ", err)

   return costLegal and cooldownLegal and seesPlayerIfNecessary,
       err
end

-- it's awkard to make these methods work independently of the canPerform
-- call chain, which routes through level:canPerform which adds the target paramters out of the Action object.

---comment
---@param level Level
--- @return boolean, boolean
function ItemAbility:canFire(level)
   -- look internally for targets
   local item = self:getTargeted(1)
   ---@cast item Actor

   if not (item) then
      prism.logger.info("Targets not set: ", item)
      return false, false
   end

   local cooldownLegal = true
   local costLegal = true
   local cost = item:get(prism.components.Cost)

   if cost and cost.ammo then
      -- see if the item has a clip.
      local clip = item:get(prism.components.Clip)
      if clip then
         if clip.ammo < cost.ammo then
            costLegal = false
         end
      else
         -- if there's no clip on the item, then see if we can consume the item itself
         local consumeableItem = item:expect(prism.components.Item)

         if consumeableItem and consumeableItem.stackable then
            if cost.ammo <= consumeableItem.stackCount then
               costLegal = true
            else
               costLegal = false
            end
         end
      end
   end

   return costLegal, cooldownLegal
end

---@return boolean, boolean, boolean, boolean
function ItemAbility:canTarget(level)
   local item = self:getTargeted(1)
   ---@cast item Actor
   local direction = self:getTargeted(2)
   ---@cast direction Vector2
   local target = self.owner:getPosition() + direction


   local rangeLegal = true
   local range = item:get(prism.components.Range)
   if range then
      local distanceToTarget = self.owner:getPosition():getRange(target, "chebyshev")
      -- prism.logger.info("direction: ", direction, " target: ", target, "distanceToTarget: ", distanceToTarget, range.min,
      --    range.max)

      rangeLegal = distanceToTarget >= range.min and distanceToTarget <= range.max
   end

   local canSeeTarget = false
   local senses = self.owner:get(prism.components.Senses)

   if senses and senses.cells:get(target:decompose()) then
      canSeeTarget = true
   end

   -- Check if there's a clear line of sight by checking visibility along the path
   -- This allows shooting over actors but not through walls
   local canPathStraightTo = false
   local source = self.owner:getPosition()

   if source and senses then
      -- Use Bresenham line to check visibility along the path
      local _, hasPath = prism.bresenham(source.x, source.y, target.x, target.y, function(x, y)
         -- Skip the starting position
         if x == source.x and y == source.y then
            return true
         end

         -- Allow the target cell (can shoot at actors)
         if x == target.x and y == target.y then
            return true
         end

         -- Check if this cell is visible to the shooter
         if not senses.cells:get(x, y) then
            return false
         end

         return true
      end)

      canPathStraightTo = hasPath
   end

   -- abort the perform if we don't still see the player in any of our target positions.

   local template = item:expect(prism.components.Template)

   -- ahhh, and player needs to be within the template.
   local requiredComponentsIfNecessary = true

   -- will pull from trigger if present, otherwise template
   local requiredComponents = self:getRequiredComponents()

   -- backwards compatibility for the boolean version

   if template.mustSeePlayerToFire then
      requiredComponents = { prism.components.PlayerController }
   end

   -- prism.logger.info("#requiredComponents: ", #requiredComponents)

   local player = level:query(prism.components.PlayerController):first()


   if requiredComponents and #requiredComponents > 0 then
      prism.logger.info("must see components to fire")

      prism.logger.info("player at: ", player:getPosition())

      -- get a list of entities that meet the requirement
      local actorWithComponentsInTrigger = false
      for _, pos in ipairs(self:getTriggerCells()) do
         local relevantActor = level:query(unpack(requiredComponents)):at(pos:decompose()):first()

         prism.logger.info("checking: ", pos)
         -- if there's an actor in range
         if relevantActor then
            prism.logger.info("found actor: ", relevantActor:getName())
            if self.owner:hasRelation(prism.relations.SensesRelation, relevantActor) then
               prism.logger.info("actor visible to ability owner")
               actorWithComponentsInTrigger = true
            end
         end
      end

      requiredComponentsIfNecessary = actorWithComponentsInTrigger
   end

   return rangeLegal, canSeeTarget, canPathStraightTo, requiredComponentsIfNecessary
end

function ItemAbility:perform(level, item, direction)
   -- apply the costs

   local cost = item:get(prism.components.Cost)
   if cost then
      if cost.ammo then
         local clip = item:get(prism.components.Clip)
         local consumeable = item:expect(prism.components.Item)
         if clip then
            clip.ammo = clip.ammo - cost.ammo
         end

         if consumeable.stackable then
            local inventory = self.owner:expect(prism.components.Inventory):removeQuantity(item, cost.ammo)
         end
      end

      -- add other cost types (health, energy) here
   end

   -- Get multi-shot count
   local multi = 1
   if cost and cost.multi then
      multi = cost.multi
   end

   -- Loop through each shot
   for shot = 1, multi do
      -- Check for miss
      local angle = 0
      local miss = false
      local range = item:get(prism.components.Range)
      if range and range.miss_odds > 0 then
         local roll = math.random()
         if roll < range.miss_odds then
            miss = true
            -- Calculate random miss angle between min_miss and max_miss with random sign
            local magnitude = range.min_miss + math.random() * (range.max_miss - range.min_miss)
            angle = magnitude * (math.random() < 0.5 and -1 or 1)

            -- Show MISS animation floating up from character like damage messages
            -- Only show for single-shot weapons (suppress for multi-shot)
            if multi == 1 then
               level:yield(prism.messages.OverlayAnimationMessage({
                  animation = spectrum.animations.TextMove(
                     self.owner,
                     "MISS",
                     prism.Vector2.UP * 2,
                     0.5, prism.Color4.BLACK, prism.Color4.RED,
                     { worldPos = true, actorOffset = prism.Vector2(-2, -2) }
                  ),
                  owner = self.owner,
                  skippable = false,
                  blocking = false
               }))
            end
         end
      end

      -- Apply miss angle to direction if needed
      local adjustedDirection = direction
      if miss and angle ~= 0 then
         -- Calculate current angle and add miss angle
         local currentAngle = math.atan2(direction.y, direction.x)
         local newAngle = currentAngle + angle
         local magnitude = direction:length()

         -- Create new direction vector with adjusted angle
         adjustedDirection = prism.Vector2(
            math.cos(newAngle) * magnitude,
            math.sin(newAngle) * magnitude
         )

         adjustedDirection = adjustedDirection:round()
      end

      -- Calculate the actual impact point using the centralized Template function
      -- This accounts for obstacles, TriggersExplosives actors, and passability masks
      local template = item:expect(prism.components.Template)

      local intendedTarget = self.owner:getPosition() + adjustedDirection
      local actualTarget = TEMPLATE.calculateActualTarget(level, self.owner, item, intendedTarget)

      prism.logger.info("intendedtarget: ", intendedTarget, " actualTarget: ", actualTarget)
      -- Use the actual target for generating effect positions
      local target = actualTarget

      -- Pass the adjusted direction (with miss angle) for template generation
      local targetForTemplate = self.owner:getPosition() + adjustedDirection

      local positions = TEMPLATE.generate(template, self.owner:getPosition(),
         targetForTemplate)

      -- Handle animations
      local animate = item:get(prism.components.Animate)
      if animate then
         if animate.name == "Flash" then
            level:yield(prism.messages.AnimationMessage({
               animation = spectrum.animations.Flash(positions, animate.duration, animate.color),
               actor = self.owner,
               blocking = true,
               skippable = true
            }))
         elseif animate.name == "Projectile" then
            -- Get all actual impact positions (handles multishot per-pellet targeting)
            local impactPositions = TEMPLATE.getAllImpactPositions(level, self.owner, item, targetForTemplate)

            if template.multishot then
               -- Multishot: fire one projectile to each actual impact position
               for _, impactPos in ipairs(impactPositions) do
                  level:yield(prism.messages.AnimationMessage({
                     animation = spectrum.animations.Projectile(animate.duration, self.owner:getPosition(),
                        impactPos,
                        animate.index,
                        animate.color,
                        { startDelay = 0 }),
                     actor = self.owner,
                     blocking = false,
                     skippable = true
                  }))
               end
            else
               -- Standard: single projectile, stagger for multi-shot (rifle burst)
               local shotDelay = (shot - 1) * (animate.duration * 0.3)
               level:yield(prism.messages.AnimationMessage({
                  animation = spectrum.animations.Projectile(animate.duration, self.owner:getPosition(), target,
                     animate.index,
                     animate.color,
                     { startDelay = shotDelay }),
                  actor = self.owner,
                  blocking = false,
                  skippable = true
               }))
            end
         end
      end

      -- Check for critical hit
      local crit = false
      local effect = item:expect(prism.components.Effect)
      if effect.crit and effect.crit > 0 then
         local roll = math.random()
         if roll <= effect.crit then
            crit = true
         end
      end

      local impacts = TEMPLATE.getAllImpactPositions(level, self.owner, item, targetForTemplate)

      if template.multishot then
         local damage, crits, push = {}, {}, {}

         for _, pos in ipairs(impacts) do
            accumulateEffects(level, self.owner, pos, effect, crit, pos, damage, crits, push)
            applyConditions(level, pos, effect)
            applySpawnEffects(level, item, pos, effect)
         end

         applyEffects(level, self.owner, damage, crits, push)
      else
         for _, pos in ipairs(impacts) do
            applyAtPosition(level, self.owner, item, pos, effect, crit, target)
         end
      end
   end -- end multi-shot loop
end

---@return Vector2[] Targeted cells, in world coordinates.
function ItemAbility:getTargetedCells()
   ---@type Actor
   local item = self:getTargeted(1)
   local template = item:expect(prism.components.Template)
   local target = self:getTargeted(2)

   return TEMPLATE.generate(template, self.owner:getPosition(), target + self.owner:getPosition())
end

---@return Vector2[] Targeted cells, in world coordinates.
function ItemAbility:getTriggerCells()
   ---@type Actor
   local item = self:getTargeted(1)
   ---@type ITemplate
   local template = item:expect(prism.components.Template)
   local trigger = item:get(prism.components.Trigger)
   local target = self:getTargeted(2)

   if trigger then
      template = trigger
   end

   return TEMPLATE.generate(template, self.owner:getPosition(), target + self.owner:getPosition())
end

---@return Component[]
function ItemAbility:getRequiredComponents()
   local item = self:getTargeted(1)

   ---@type ITemplate
   local template = item:expect(prism.components.Template)
   local trigger = item:get(prism.components.Trigger)

   if trigger then
      template = trigger
   end

   return template.requiredComponents
end

---@return Actor
function ItemAbility:getItem()
   return self:getTargeted(1)
end

return ItemAbility
