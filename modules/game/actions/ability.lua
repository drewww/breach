local Item = prism.targets.InventoryTarget()

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

   prism.logger.info("mustSeePlayerToFire: ", template.mustSeePlayerToFire, " itemName: ", item:getName())

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

      local animate = item:get(prism.components.Animate)
      local effect = item:expect(prism.components.Effect)

      -- Check for critical hit (done once per shot, applies to all projectiles in spread)
      local crit = false
      if effect.crit and effect.crit > 0 then
         local roll = math.random()
         if roll <= effect.crit then
            crit = true
         end
      end

      -- SPREAD-FIRE MODE: Fire multiple projectiles across an arc (e.g., shotgun)
      -- Each projectile traces its own line; actors can be hit multiple times
      if template.projectiles and template.projectiles > 1 then
         local mask = prism.Collision.createBitmaskFromMovetypes(template.mask or { "walk" })
         local endpoints = TEMPLATE.generateProjectileEndpoints(template, self.owner:getPosition(), targetForTemplate)

         -- Track how many times each actor gets hit (for multiple pellet hits)
         local actorHits = {}

         -- Process each projectile
         for pelletIndex, endpoint in ipairs(endpoints) do
            -- Trace the projectile path
            local pelletPositions = TEMPLATE.traceProjectilePath(self.owner:getPosition(), endpoint, mask, level)

            -- Fire projectile animation (all at once, no stagger for spread)
            if animate and animate.name == "Projectile" then
               -- Use the last position in the path as the actual target for animation
               local animTarget = #pelletPositions > 0 and pelletPositions[#pelletPositions] or endpoint
               level:yield(prism.messages.AnimationMessage({
                  animation = spectrum.animations.Projectile(animate.duration, self.owner:getPosition(), animTarget,
                     animate.index,
                     animate.color,
                     { startDelay = 0 }),
                  actor = self.owner,
                  blocking = false,
                  skippable = true
               }))
            end

            -- Check each position along this pellet's path for actors
            for _, pos in ipairs(pelletPositions) do
               local actorsAtPos = level:query():at(pos:decompose()):gather()
               for _, actor in ipairs(actorsAtPos) do
                  if actor ~= self.owner then
                     actorHits[actor] = (actorHits[actor] or 0) + 1
                  end
               end
            end
         end

         -- Flash animation for spread weapons (covers whole area)
         if animate and animate.name == "Flash" then
            local positions = TEMPLATE.generate(template, self.owner:getPosition(), targetForTemplate)
            level:yield(prism.messages.AnimationMessage({
               animation = spectrum.animations.Flash(positions, animate.duration, animate.color),
               actor = self.owner,
               blocking = true,
               skippable = true
            }))
         end

         -- Apply effects to each actor based on how many pellets hit them
         for actor, hitCount in pairs(actorHits) do
            prism.logger.info("spread-fire: ", actor:getName(), " hit ", hitCount, " times")

            for hit = 1, hitCount do
               local damage = 0

               if effect.push and actor then
                  local vector = actor:getPosition() - self.owner:getPosition()

                  local pushAmount = effect.push
                  if crit then
                     pushAmount = pushAmount * 2
                  end

                  local action = prism.actions.Push(self.owner, actor, vector:normalize(), pushAmount, true)
                  local s, e = level:tryPerform(action)

                  if action.collision then
                     damage = damage + COLLISION_DAMAGE
                  end
               end

               if effect.health and actor then
                  local finalDamage = effect.health + damage
                  if crit then
                     finalDamage = finalDamage * 2
                  end
                  level:tryPerform(prism.actions.Damage(self.owner, actor, finalDamage, crit and hit == 1))
               end
            end
         end
      else
         -- STANDARD MODE: Hit all cells in template shape once

         local positions = TEMPLATE.generate(template, self.owner:getPosition(),
            targetForTemplate)

         -- if we have an animation, call for it here.
         if animate then
            if animate.name == "Flash" then
               level:yield(prism.messages.AnimationMessage({
                  animation = spectrum.animations.Flash(positions, animate.duration, animate.color),
                  actor = self.owner,
                  blocking = true,
                  skippable = true
               }))
            elseif animate.name == "Projectile" then
               -- Stagger multi-shot projectiles so they overlap in flight
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

         -- apply the effect to each location.
         for _, pos in ipairs(positions) do
            prism.logger.info("effect position: ", pos)

            local actorsAtPos = level:query():at(pos:decompose()):gather()

            -- for now, we only support damage type effects. So, do this.
            for _, actor in ipairs(actorsAtPos) do
               -- accumulate damage from push into this
               local damage = 0
               if effect.push and actor then
                  -- we probably need a flag on effect, which is "push from template center"
                  -- we can generalize it too, so we could have a one directional push.
                  local vector = actor:getPosition() - self.owner:getPosition()

                  if effect.pushFromCenter then
                     vector = actor:getPosition() - target
                  end

                  -- Double push distance on crit
                  local pushAmount = effect.push
                  if crit then
                     pushAmount = pushAmount * 2
                  end

                  -- the last "true" suppresses damage application
                  local action = prism.actions.Push(self.owner, actor, vector:normalize(), pushAmount, true)
                  local s, e = level:tryPerform(action)

                  prism.logger.info("push result: ", s, e)
                  if action.collision then
                     damage = damage + COLLISION_DAMAGE
                  end
               end

               if effect.health and actor then
                  -- Apply crit multiplier if crit occurred
                  local finalDamage = effect.health + damage
                  if crit then
                     finalDamage = finalDamage * 2
                  end
                  -- Pass crit flag to damage action
                  local s, e = level:tryPerform(prism.actions.Damage(self.owner, actor, finalDamage, crit))
               end
            end

            if effect.spawnActor then
               local spawnedActor
               if effect.actorOptions then
                  spawnedActor = prism.actors[effect.spawnActor](unpack(effect.actorOptions))
               else
                  spawnedActor = prism.actors[effect.spawnActor]()
               end
               level:addActor(spawnedActor, pos:decompose())
            end

            if animate and animate.explode then
               local distance = target:getRange(pos, "euclidean")
               prism.logger.info("exploding with radius ", animate.radius)
               level:yield(prism.messages.AnimationMessage({
                  animation = spectrum.animations.Explosion(pos, 0.2 * animate.radius + 0.1, prism.Color4.YELLOW),
                  actor = self.owner,
                  blocking = false,
                  skippable = false
               }))
            end
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
