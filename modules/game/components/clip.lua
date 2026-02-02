--- @class ClipOptions
--- @field ammo integer Ammo available.
--- @field max integer Max ammo store-able in this component.
--- @field type string Ammo type to draw from when reloading.
--- @field turns integer Number of turns required to reload.


--- Stores ammo inside an item.
--- @class Clip : Component
--- @field ammo integer Ammo available.
--- @field max integer Max ammo store-able in this component.
--- @field type string Ammo type to draw from when reloading.
--- @field reloading integer Count of turns invested in reloading.
--- @field turns integer Number of turns required to reload.

local Clip = prism.Component:extend("Clip")
Clip.name = "Clip"

---@param options ClipOptions
function Clip:__new(options)
   self.ammo = options.ammo or 0
   self.max = options.max or 0
   self.type = options.type or "none"
   self.reloading = 0
   self.turns = options.turns or 1
end

return Clip
