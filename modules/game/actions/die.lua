---@class Die : Action
local Die = prism.Action:extend("Die")

function Die:canPerform(level)
   return level:hasActor(self.owner)
end

function Die:perform(level)
   level:removeActor(self.owner)
end

return Die
