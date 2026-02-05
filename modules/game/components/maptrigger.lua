--- @class MapTrigger : Component
--- @field type string
local MapTrigger = prism.Component:extend("MapTrigger")
MapTrigger.name = "MapTrigger"

function MapTrigger:__new(type)
   self.type = type or "none"
end

return MapTrigger
