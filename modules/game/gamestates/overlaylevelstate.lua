--- @class OverlayLevelState : LevelState
--- A specialized LevelState that uses two displays instead of one, overload.
--- @field overlayDisplay Display The overlay display (which by convention has double resolution of the main Display)
--- @field panels Panel[] An array of panels.
--- @field blendBG fun(self: OverlayLevelState, x: integer, y: integer, color: Color4, display?: Display): nil Blends a color with the current background using additive blending

--- @overload fun(level: Level, display: Display, microDisplay: Display): OverlayLevelState

local OverlayLevelState = spectrum.gamestates.LevelState:extend "OverlayLevelState"

--- @param level Level
--- @param display Display
--- @param overlayDisplay Display
function OverlayLevelState:__new(level, display, overlayDisplay)
   self.overlayDisplay = overlayDisplay
   self.display = display

   self.panels = {}

   OverlayLevelState.super.__new(self, level, display)
end

function OverlayLevelState:update(dt)
   OverlayLevelState.super.update(self, dt)

   self.overlayDisplay:update(self.level, dt)
end

--- @param message Message
function OverlayLevelState:handleMessage(message)
   -- if we are receiving an animation for the overlay display,
   -- dispatch it appropriately. otherwise, dispatch normally.
   if prism.messages.OverlayAnimationMessage:is(message) then
      ---@cast message AnimationMessage
      self.overlayDisplay:yieldAnimation(message)
   else
      spectrum.gamestates.LevelState.handleMessage(self, message)
   end
end

-- --- @param panel Panel
function OverlayLevelState:addPanel(panel)
   table.insert(self.panels, panel)
end

-- --- @parm panel Panel
function OverlayLevelState:removePanel(panel)
   table.remove(self.panels, panel)
end

function OverlayLevelState:putPanels()
   for _, p in ipairs(self.panels) do
      p:put(self.level)
   end
end

--- Returns the X-coordinate, Y-coordinate, and cell the mouse is over, if the mouse is over a cell.
--- @return integer? x
--- @return integer? y
function OverlayLevelState:getOverlayPosUnderMouse()
   local mx, my = love.mouse.getPosition()
   return self.overlayDisplay:getCellUnderMouse(self:transformMousePosition(mx, my))
end

--- Blends a color with the current background color of a cell using additive blending.
--- This simulates two colored lights shining on the same spot.
--- @param x integer The x-coordinate of the cell.
--- @param y integer The y-coordinate of the cell.
--- @param color Color4 The color to blend.
--- @param display? Display The display to blend on (defaults to overlayDisplay if not provided)
function OverlayLevelState:blendBG(x, y, color, display)
   display = display or self.overlayDisplay

   -- Apply camera offset if pushed
   local cellX, cellY = x, y
   if display.pushed then
      cellX = x + display.camera.x
      cellY = y + display.camera.y
   end

   -- Check bounds
   if cellX < 1 or cellX > display.width or cellY < 1 or cellY > display.height then return end

   -- Get the current background color
   local cell = display.cells[cellX] and display.cells[cellX][cellY]
   if not cell then return end

   local currentBG = cell.bg

   -- Additive blend: result = color1 + color2 (clamped to 1.0)
   local blendedColor = prism.Color4(
      math.min(currentBG.r + color.r, 1),
      math.min(currentBG.g + color.g, 1),
      math.min(currentBG.b + color.b, 1),
      math.min(currentBG.a + color.a, 1)
   )

   -- Set the blended color back (putBG will apply camera offset again, so use cell coordinates directly)
   blendedColor:copy(cell.bg)
end

return OverlayLevelState
