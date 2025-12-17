local Item = prism.targets.InventoryTarget()

-- Currently this is in world positions.
-- TODO change it to be relative position so we can re-use it for
-- NPC intents.
local TargetPosition = prism.Target():isVector2()

---@class ItemAbility : Action
local ItemAbility = prism.Action:extend("ItemAbility")

ItemAbility.targets = { Item, TargetPosition }

function ItemAbility:canPerform(level, item, position)
   -- Check the constraint components on the item: range, cost, cooldown.
   local rangeLegal = true
   local range = item:get(prism.components.Range)
   if range then
      local distanceToTarget = self.owner:getPosition():getRange(position, "chebyshev")
      rangeLegal = distanceToTarget >= range.min and distanceToTarget <= range.max
   end

   prism.logger.info("ABILITY: rangeLegal=", rangeLegal)

   local costLegal = true
   local cost = item:get(prism.components.Cost)

   if cost.ammo then
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

   prism.logger.info("costLegal=", costLegal)

   -- TODO add non-ammo costs (health for now, then energy)

   -- TODO
   local cooldownLegal = true
   local cooldown = item:get(prism.components.Cooldown)

   return rangeLegal and costLegal and cooldownLegal
end

function ItemAbility:perform(level, item, position)
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

   -- get a list of effected locations. Ability required to have a template.
   -- (self-casting might ... relax this? or we may impement that stil as a template. )
   local template = item:expect(prism.components.Template)
   local positions = prism.components.Template.generate(template, self.owner:getPosition(), position)

   -- apply the effect to each location.
   local effect = item:expect(prism.components.Effect)
   for _, pos in ipairs(positions) do
      local actorsAtPos = level:query():at(pos:decompose()):gather()

      -- for now, we only support damage type effects. So, do this.
      for _, actor in ipairs(actorsAtPos) do
         if effect.health and actor then
            -- TODO pass in piercing metadata
            local s, e = level:tryPerform(prism.actions.Damage(self.owner, actor, effect.health))
         end

         if effect.push and actor then
            -- TODO abstract this to adapt to push from different angles, i.e. a rocket pushing from the center.
            local vector = actor:getPosition() - self.owner:getPosition()
            level:tryPerform(prism.actions.Push(self.owner, actor, vector:normalize(), effect.push))
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
   end
end

---@return Vector2[] Targeted cells, in world coordinates.
function ItemAbility:getTargetedCells()
   ---@type Actor
   local item = self:getTargeted(1)
   local template = item:expect(prism.components.Template)
   local target = self:getTargeted(2)

   return template:generate(self.owner:getPosition(), target)
end

---@return Actor
function ItemAbility:getItem()
   return self:getTargeted(1)
end

return ItemAbility
