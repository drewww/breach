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

      level:perform(prism.actions.SetState(self.owner, "FOLLOWING"))
   end

   return true
end

return SetLeader
