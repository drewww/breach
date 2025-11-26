--- @class Gas : Component
--- @field volume number
--- @field nextVolume number
local Gas = prism.Component:extend("Gas")
Gas.name = "Gas"

function Gas:__new(volume)
   self.volume = volume
   self.nextVolume = volume
end

return Gas
