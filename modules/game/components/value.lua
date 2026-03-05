--- @class Value : Component
--- @field credits integer
local Value = prism.Component:extend("Value")
Value.name = "Value"

function Value:__new(credits)
   self.credits = credits
end

return Value
