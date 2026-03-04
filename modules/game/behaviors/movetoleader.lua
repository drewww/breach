--- @class MoveToLeader : BehaviorTree.Node
local MoveToLeader = prism.BehaviorTree.Node:extend("MoveToLeader")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function MoveToLeader:run(level, actor, controller)
   local leader = actor:getRelation(prism.relations.FollowsRelation)

   if not leader then return false end

   local destination = leader:getPosition()
   local mover = actor:expect(prism.components.Mover)

   local path = level:findPath(actor:getPosition(), destination, actor, mover.mask, 1, "8way", function(x, y)
      -- TODO add wall adjacency avoiding here
      return 1
   end)

   if path then
      local nextStep = path:pop()

      local direction = (nextStep - actor:getPosition())

      direction = prism.Vector2(
         direction.x == 0 and 0 or (direction.x > 0 and 1 or -1),
         direction.y == 0 and 0 or (direction.y > 0 and 1 or -1)
      )
      local action = prism.actions.Move(actor, direction, false)
      local s, e = level:canPerform(action)

      if s then
         return action
      else
         return false
      end
   else
      return false
   end
end

return MoveToLeader
