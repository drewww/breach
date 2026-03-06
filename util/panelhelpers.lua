--- Utility functions for drawing UI elements in panels
local PanelHelpers = {}

--- Draws a segmented bar with alternating color shading
--- @param display Display The display to draw on
--- @param x integer Starting x position for the bar
--- @param y integer Y position for the bar
--- @param current integer Current value (filled segments)
--- @param max integer Maximum value (total segments)
--- @param color Color4 Base color for filled segments
function PanelHelpers.drawBar(display, x, y, current, max, color)
   for i = 1, max do
      -- Alternate between base color and slightly darker version
      local barColor = i % 2 == 0 and color or color:lerp(prism.Color4.BLACK, 0.1)

      -- Empty segments are grey
      if i > current then
         barColor = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
      end

      display:rectangle("fill", x + i - 1, y, 1, 1, " ", prism.Color4.TRANSPARENT, barColor)
   end
end

return PanelHelpers
