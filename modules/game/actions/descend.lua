local Stair = prism.Target(prism.components.Stair):range(1)

---@class Descend : Action
local Descend = prism.Action:extend("Descend")

Descend.targets = { Stair }

function Descend:canPerform()
   return true
end

function Descend:perform(level, stair)
   level:removeActor(self.owner)
   level:yield(prism.messages.DescendMessage())
end

return Descend
