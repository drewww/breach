local Leader = prism.Target():isActor()

-- TODO fix when boolean targets are working
local SuppressAnimation = prism.Target():isType("number"):optional()

---@class SetLeader : Action
local SetLeader = prism.Action:extend("SetLeader")

SetLeader.targets = { Leader, SuppressAnimation }

function SetLeader:canPerform()
   return true
end

function SetLeader:perform(level, leader, supressAnimation)
   if leader then
      self.owner:addRelation(prism.relations.FollowsRelation(), leader)

      if not supressAnimation or supressAnimation == "0" then
         level:yield(prism.messages.OverlayAnimationMessage({
            animation = spectrum.animations.TextReveal(self.owner, "Found Leader!", 0.5, 1.5, prism.Color4.BLACK,
               prism.Color4.YELLOW, { worldPos = true, actorOffset = prism.Vector2(1, -1) }
            ),
            actor = self.owner,
            blocking = true,
            skippable = false
         }))
      end
   end

   return true
end

return SetLeader
