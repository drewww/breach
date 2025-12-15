local Item = prism.Target():isActor()
local TargetPosition = prism.Target():isVector2()

---@class ItemAbility : Action
local ItemAbility = prism.Action:extend("ItemAbility")

ItemAbility.targets = { Item, TargetPosition }

function ItemAbility:canPerform(level, item, position)
   prism.logger.info("canPerform ability: ", level, item, position)
   -- Check the constraint components on the item: range, cost, cooldown.
   local rangeLegal = true
   local range = item:get(prism.components.Range)
   if range then
      local distanceToTarget = self.owner:getPosition():getRange(position, "chebyshev")
      rangeLegal = distanceToTarget >= range.min and distanceToTarget <= range.max
   end

   prism.logger.info("ABILITY: rangeLegal=", rangeLegal)

   -- TODO
   local costLegal = true
   local cost = item:get(prism.components.Cost)

   -- TODO
   local cooldownLegal = true
   local cooldown = item:get(prism.components.Cooldown)

   return rangeLegal and costLegal and cooldownLegal
end

function ItemAbility:perform(level, item, position)
   -- apply the costs
   -- TODO

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
            prism.logger.info("damage: ", s, e, effect.health)
         end

         if effect.push and actor then
            -- TODO abstract this to adapt to push from different angles, i.e. a rocket pushing from the center.
            local vector = actor:getPosition() - self.owner:getPosition()
            level:tryPerform(prism.actions.Push(self.owner, actor, vector:normalize(), effect.push))
         end
      end
   end
end

return
    ItemAbility
