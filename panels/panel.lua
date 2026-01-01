---@class Panel : Object
--- @field display Display
--- @field pos Vector2
local Panel = prism.Object:extend("Panel")

--- @param display Display
--- @param pos Vector2
function Panel:__new(display, pos)
   self.display = display
   self.pos = pos
end

function Panel:preparePut()
   self.priorCamera = self.display.camera:copy()
   self.display:setCamera(self.pos:decompose())
   self.display:beginCamera()
end

function Panel:cleanupPut()
   self.display:endCamera()
   self.display.camera = self.priorCamera
end

return Panel
