--- @class DetectPlayer : BehaviorTree.Node
local DetectPlayer = prism.BehaviorTree.Node:extend("DetectPlayer")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function DetectPlayer:run(level, actor, controller)
   -- update the historical tracking of known player location.
   -- if it's been more than 20 turns since we've seen the player, delete our memory of the location.
   if controller.blackboard.player then
      controller.blackboard.playerPosAge = controller.blackboard.playerPosAge + 1

      if controller.blackboard.playerPosAge > 20 then
         controller.blackboard.player = nil
         controller.blackboard.playerPosAge = -1
         prism.logger.info("Expiring memory of player location.")
      end
   end

   -- this is the logic that SHOULD work
   for entity, relation in pairs(actor:getRelations(prism.relations.SensesRelation)) do
      prism.logger.info("sensed: ", entity)
      if entity:has(prism.components.PlayerController) then
         controller.blackboard.player = entity:getPosition()
         controller.blackboard.playerPosAge = 0

         prism.logger.info("Sighted player, storing player location: ", entity:getPosition())
      end
   end

   -- always returns true
   -- we may want to change this design; it could be the return value here is used to fork into two branches of the behavior tree based on whether we have awareness of the player.
   return true
end

return DetectPlayer
