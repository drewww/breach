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
         local oX, oY = (self.owner:getPosition() * 2):decompose()
         oX, oY = oX + 1, oY - 1

         level:yield(prism.messages.OverlayAnimationMessage({
            animation = spectrum.animations.TextReveal(oX, oY, "Found Leader!", 0.5, 1.5, prism.Color4.BLACK,
               prism.Color4.YELLOW
            ),
            blocking = true,
            skippable = false
         }))
      end
   end

   return true
end

return SetLeader
