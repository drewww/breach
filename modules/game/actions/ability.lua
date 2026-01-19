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
   local senses = self.owner:expect(prism.components.Senses)
   local source = self.owner:getPosition()

   if source and senses then
      -- Use Bresenham line to check visibility along the path
      local _, hasPath = prism.Bresenham(source.x, source.y, target.x, target.y, function(x, y)
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

   -- if the item has MustSeePlayer component, then check that.
   -- how do we generalize this between player and enemy?
   -- we could move this to the intentful turn handler. but it feels like awfully game-specific logic to put it there.
   -- we do check canPerform in that context
   -- abort the perform if we don't still see the player in any of our target positions.

   local seesPlayer = false
   local template = item:expect(prism.components.Template)

   if template.mustSeePlayerToFire then
      local positions = prism.components.Template.generate(template, self.owner:getPosition(),
         target)
      for _, position in ipairs(positions) do
         local player = level:query(prism.components.PlayerController):at(position:decompose()):first()
         if player then
            seesPlayer = true
         end
      end
   end

   local targetContainsPlayerIfNecessary = true

   if template.mustSeePlayerToFire then
      targetContainsPlayerIfNecessary = seesPlayer
   end


   return rangeLegal, canSeeTarget, canPathStraightTo, targetContainsPlayerIfNecessary
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

   -- Calculate the actual impact point using the centralized Template function
   -- This accounts for obstacles, TriggersExplosives actors, and passability masks
   local template = item:expect(prism.components.Template)

   local intendedTarget = self.owner:getPosition() + direction
   local actualTarget = template.calculateActualTarget(level, self.owner, item, intendedTarget)

   -- Use the actual target for generating effect positions
   local target = actualTarget

   local positions = prism.components.Template.generate(template, self.owner:getPosition(),
      target)

   -- if we have an animation, call for it here.
   -- now part of the problem here is that perhaps we need to standardize the animations in some way. we have a color-type animation in laser, which takes points. for now, we'll special-case each one. maybe later we get smart about this.
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
         level:yield(prism.messages.AnimationMessage({
            animation = spectrum.animations.Projectile(animate.duration, self.owner:getPosition(), target, animate.index,
               animate.color),
            actor = self.owner,
            blocking = true,
            skippable = true
         }))
      end
   end

   -- apply the effect to each location.
   local effect = item:expect(prism.components.Effect)
   for _, pos in ipairs(positions) do
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

            -- the last "true" suppresses damage application
            local action = prism.actions.Push(self.owner, actor, vector:normalize(), effect.push, true)
            level:tryPerform(action)
            if action.collision then
               damage = damage + COLLISION_DAMAGE
            end
         end

         if effect.health and actor then
            -- TODO pass in piercing metadata
            local s, e = level:tryPerform(prism.actions.Damage(self.owner, actor, effect.health + damage))
         end
      end

      if effect.spawnActor then
         local actor
         if effect.actorOptions then
            actor = prism.actors[effect.spawnActor](unpack(effect.actorOptions))
         else
            actor = prism.actors[effect.spawnActor]()
         end
         level:addActor(actor, pos:decompose())
      end

      -- prism.logger.info("EXPLODE? ", animate.explode, " at ", pos)
      if animate.explode then
         local distance = target:getRange(pos, "euclidean")
         -- TODO think about this actor setting. we like masking the animation
         -- via actor sensing. but if we're not spawning anything in, how do we do it? we may need to spawn in a dummy actor that expires??
         level:yield(prism.messages.AnimationMessage({
            animation = spectrum.animations.Explosion(pos, 0.2 * distance + 0.1, prism.Color4.YELLOW),
            actor = actor,
            blocking = false,
            skippable = false
         }))
      end
   end
end

---@return Vector2[] Targeted cells, in world coordinates.
function ItemAbility:getTargetedCells()
   ---@type Actor
   local item = self:getTargeted(1)
   local template = item:expect(prism.components.Template)
   local target = self:getTargeted(2)

   return template:generate(self.owner:getPosition(), target + self.owner:getPosition())
end

---@return Actor
function ItemAbility:getItem()
   return self:getTargeted(1)
end

return ItemAbility
