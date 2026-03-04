--- @class LeaderPlan : BehaviorTree.Node
local LeaderPlan = prism.BehaviorTree.Node:extend("LeaderPlan")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function LeaderPlan:run(level, actor, controller)
   local leader = actor:getRelation(prism.relations.FollowsRelation)

   -- if no leader, return true so we can move on to the next planner
   if not leader then return true end

   local s, e = level:perform(prism.actions.SetDestination(actor, leader:getPosition(), false))
   -- if we got this far, and we have a leader, this is the planning
   -- method for us. return false to stop further planning.
   return false
end

return LeaderPlan
