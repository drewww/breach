--- @class Health : Component
--- @field value number current health value
--- @field initial number initial health value, generally the "max"

local Health = prism.Component:extend("Health")
Health.name = "Health"

function Health:__new(value)
   self.value = value
   self.initial = value
end

return Health
