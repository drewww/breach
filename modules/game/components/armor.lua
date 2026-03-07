--- @class Armor : Component
--- @field strength integer
local Armor = prism.Component:extend("Armor")
Armor.name = "Armor"

function Armor:__new(strength)
   self.strength = strength
end

return Armor
