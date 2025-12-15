--- @class CostOptions
--- @field ammo? number Ammo used per use (default: 0)
--- @field ammoType? string Ammo type required (default: "")
--- @field hp? number Health cost per use (default: 0)
--- @field energy? number Energy cost per use (default: 0)

--- Represents the cost to use the ability.
--- @class Cost : Component
--- @field ammo number Ammo used per use.
--- @field ammoType string TODO figure out how to represent ammo types. This is a deeper project.
--- @field hp number Health cost per use.
--- @field energy number Energy cost per use.

local Cost = prism.Component:extend("Cost")
Cost.name = "Cost"

---@param options CostOptions
function Cost:__new(options)
   options = options or {}

   self.ammo = options.ammo or 0
   self.ammoType = options.ammoType or ""
   self.hp = options.hp or 0
   self.energy = options.energy or 0
end

return Cost
