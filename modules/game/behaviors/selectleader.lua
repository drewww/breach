local SelectLeaderBehavior = prism.BehaviorTree.Node:extend("SelectLeaderBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function SelectLeaderBehavior:run(level, actor, controller)
   if not actor:hasRelation(prism.relations.FollowsRelation) then
      local leader = level:query(prism.components.Leader):first()

      if leader then
         local setLeaderAction = prism.actions.SetLeader(actor, leader)

         level:tryPerform(setLeaderAction)
      else
         local oX, oY = (actor:getPosition() * 2):decompose()
         oX, oY = oX + 1, oY - 1

         level:yield(prism.messages.OverlayAnimationMessage({
            animation = spectrum.animations.TextReveal(actor, "No leader...", 0.5, 1.5, prism.Color4.BLACK,
               prism.Color4.YELLOW, { worldPos = true, actorOffset = prism.Vector2(1, -1) }
            ),
            blocking = true,
            skippable = false,
         }))
         return false
      end
   end
   return false
end

return SelectLeaderBehavior
