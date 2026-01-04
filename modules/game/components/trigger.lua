--- @class Trigger : Component
--- @field type string
local Trigger = prism.Component:extend("Trigger")
Trigger.name = "Trigger"

function Trigger:__new(type)
   self.type = type or "none"
end

return Trigger
