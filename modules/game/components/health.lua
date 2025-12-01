--- @class Health : Component
--- @field value number
local Health = prism.Component:extend("Health")
Health.name = "Health"

function Health:__new(value)
   self.value = value
end

return Health
