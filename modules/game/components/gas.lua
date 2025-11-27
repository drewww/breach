--- @class Gas : Component
--- @field volume number Amount of gas in this Actor.
--- @field type "poison"|"smoke"|"fire" Type of gas. Implies different diffusion parameters and effects on the player.
--- @field updated boolean Used by the diffusion system for garbage collection; do not interact with otherwise.
local Gas = prism.Component:extend("Gas")
Gas.name = "Gas"

---@param volume number Amount of gas to start with.
---@param type "poison"|"smoke"|"fire" Type of gas. Implies different diffusion parameters and effects on the player.
function Gas:__new(type, volume)
   self.volume = volume
   self.updated = true
   self.type = type
end

return Gas
