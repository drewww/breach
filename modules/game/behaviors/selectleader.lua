--- @class SelectLeaderBehavior : BehaviorTree.Node
local SelectLeaderBehavior = prism.BehaviorTree.Node:extend("SelectLeaderBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function SelectLeaderBehavior:run(level, actor, controller)
   if not actor:has(prism.components.Follower) then return false end

   if not actor:hasRelation(prism.relations.FollowsRelation) then
      local leaders = level:query(prism.components.Leader):gather()

      if #leaders > 0 then
         local pos = actor:getPosition()

         if pos then
            table.sort(leaders, function(a, b)
               return pos:distance(a:getPosition()) <
                   pos:distance(b:getPosition())
            end)

            level:tryPerform(prism.actions.SetLeader(actor, leaders[1]))
            return true
         end
      end

      return false
   end
   return false
end

return SelectLeaderBehavior
