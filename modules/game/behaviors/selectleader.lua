local SelectLeaderBehavior = prism.BehaviorTree.Node:extend("SelectLeaderBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function SelectLeaderBehavior:run(level, actor, controller)
   if not actor:hasRelation(prism.relations.FollowsRelation) then
      local leader = level:query(prism.components.Leader):first()

      local oX, oY = (actor:getPosition() * 2):decompose()
      oX, oY = oX + 1, oY - 1
      if leader then
         actor:addRelation(prism.relations.FollowsRelation(), leader)

         level:yield(prism.messages.OverlayAnimationMessage({
            animation = spectrum.animations.TextReveal(oX, oY, "Found Leader!", 0.5, 1.5, prism.Color4.BLACK,
               prism.Color4.YELLOW
            ),
            blocking = true,
            skippable = false,
            camera = true
         }))
      else
         level:yield(prism.messages.OverlayAnimationMessage({
            animation = spectrum.animations.TextReveal(oX, oY, "No leader...", 0.5, 1.5, prism.Color4.BLACK,
               prism.Color4.YELLOW
            ),
            blocking = true,
            skippable = false,
            camera = true
         }))
         return false
      end
   end
   return false
end

return SelectLeaderBehavior
