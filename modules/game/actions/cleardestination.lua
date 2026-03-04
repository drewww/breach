---@class ClearDestination : Action
local ClearDestination = prism.Action:extend("ClearDestination")

ClearDestination.targets = {}

function ClearDestination:canPerform()
   return true
end

function ClearDestination:perform(level)
   self.owner:remove(prism.components.Destination)
   self.owner:give(prism.components.Destination())
end

return ClearDestination
