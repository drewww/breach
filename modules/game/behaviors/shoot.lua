--- @class ShootBehavior : BehaviorTree.Node
local ShootBehavior = prism.BehaviorTree.Node:extend("ShootBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller, IIntentful
--- @return boolean|Action
function ShootBehavior:run(level, actor, controller)
   prism.logger.info("running shoot behavior")
   -- pick a location to shoot. for now, just pick a random one.
   local inventory = actor:get(prism.components.Inventory)

   if not inventory then return false end

   local weapon = inventory:query(prism.components.Active):first()

   if not weapon then return false end

   local range = weapon:expect(prism.components.Range)
   local template = weapon:expect(prism.components.Template)

   -- now we have a weapon to use, see if we can use it to shoot a target

   -- see if we can sense the player
   local targetActor = nil
   -- for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
   --    ---@cast entity Actor
   --    if entity:has(prism.components.PlayerController) then
   --       targetActor = entity
   --    end
   -- end

   -- try a version that uses range directly instead of SeesRelation
   local player = level:query(prism.components.PlayerController):first()

   if player then
      local rangeToPlayer = player:getPosition():getRange(actor:getPosition(), "chebyshev")

      -- in the burst case, we want to add in the effect range.
      prism.logger.info("rangeToPlayer: ", rangeToPlayer, range.min, range.max, template.range)
      if rangeToPlayer < range.min or rangeToPlayer > range.max + template.range then
         return false
      else
         targetActor = player
      end
   end


   if not targetActor then
      prism.logger.info("No player target sensed (in range mode).")
      return false
   end

   -- multiplying by range.max makes sure that we don't pick a target position beyond our max range. in the case of a "self-burst" type weapon this will also move the target space back to the actor's original location.
   local direction = targetActor:getPosition() - actor:getPosition()
   local shoot = prism.actions.ItemAbility(actor, weapon, direction * range.max)

   local s, e = level:canPerform(shoot)

   if s then
      return shoot
   else
      prism.logger.info("Failed to shoot with error: ", e)
      return false
   end
end

return ShootBehavior
