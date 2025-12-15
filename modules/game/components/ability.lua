--- An entity with the Ability component means you use the Item to power an ItemAbility action.
--- @class Ability : Component
local Ability = prism.Component:extend("Ability")
Ability.name = "Ability"


function Ability:__new()
end

return Ability
