local Panel = prism.Object:extend("Panel")

function Panel:__new(display)
   self.display = display
end

---@param level Level
function Panel:put(level)
end

return Panel
