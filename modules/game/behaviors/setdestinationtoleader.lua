local SetDestinationToLeaderBehavior = prism.BehaviorTree.Node:extend("SetDestinationToLeader")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function SetDestinationToLeaderBehavior:run(level, actor, controller)
   -- TODO make sure the destination is pathable

   local leader = actor:getRelation(prism.relations.FollowsRelation)

   if leader and prism.Actor:is(leader) then
      -- TODO consider setting this to the leader's INTENDED position
      local setDestinationAction = prism.actions.SetDestination(actor, prism.Vector2(leader:getPosition():decompose()),
         1)
      local success, err = level:tryPerform(setDestinationAction)
      prism.logger.info("leaderdest: ", success, err)
      return success
   else
      return false
   end

   return false
end

return SetDestinationToLeaderBehavior
