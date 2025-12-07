local Panel = prism.Object:extend("Panel")

function Panel:__new(display)
   self.display = display
end

---@param level Level
function Panel:put(level)
   self.display:print(1, 1, "PANEL", prism.Color4.WHITE)
end

return Panel
