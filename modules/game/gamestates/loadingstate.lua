local LoadingState = spectrum.GameState:extend("LoadingState")

--- Creates a new LoadingState that runs world generation and displays progress
--- @param generator TunnelWorldGenerator The world generator to run
--- @param display Display The display to render to
--- @param overlayDisplay Display The overlay display for UI elements
function LoadingState:__new(generator, display, overlayDisplay)
   spectrum.GameState.__new(self)

   self.generator = generator
   self.display = display
   self.overlayDisplay = overlayDisplay
   self.generationCoroutine = coroutine.create(function()
      return self.generator:generate()
   end)
   self.complete = false
   self.builder = nil
end

function LoadingState:update(dt)
   if self.complete then
      return
   end

   -- Resume the generation coroutine
   local success, result = coroutine.resume(self.generationCoroutine)

   if not success then
      -- Error occurred
      prism.logger.error("World generation error: " .. tostring(result))
      self.complete = true
      return
   end

   -- Check if generation is complete
   if coroutine.status(self.generationCoroutine) == "dead" then
      self.complete = true
      self.builder = result
      prism.logger.info("World generation complete!")

      -- Transition to PlayState with the generated world (lazy load to avoid circular dependency)
      local PlayState = require "modules.game.gamestates.playstate"
      local playState = PlayState(self.display, self.overlayDisplay, self.builder)
      self:getManager():push(playState)
   end
end

function LoadingState:draw()
   -- Clear displays
   self.display:clear()
   self.overlayDisplay:clear()

   -- Get progress info from generator
   local progress = self.generator:getProgress()

   -- Center the text on screen
   local centerX = math.floor(SCREEN_WIDTH / 2)
   local centerY = math.floor(SCREEN_HEIGHT / 2)

   -- Draw title
   local title = "GENERATING FACILITY"
   self.overlayDisplay:print(
      centerX - math.floor(#title / 2),
      centerY - 3,
      title,
      prism.Color4.WHITE
   )

   -- Draw progress bar
   local barWidth = 40
   local barX = centerX - math.floor(barWidth / 2)
   local barY = centerY - 1
   local fillWidth = math.floor((progress.current / progress.total) * barWidth)

   -- Draw bar background
   for i = 0, barWidth - 1 do
      self.overlayDisplay:print(barX + i, barY, "─", prism.Color4.GRAY)
   end

   -- Draw bar fill
   for i = 0, fillWidth - 1 do
      self.overlayDisplay:print(barX + i, barY, "█", prism.Color4.CYAN)
   end

   -- Draw percentage
   local percentText = string.format("%d%%", progress.percentage)
   self.overlayDisplay:print(
      centerX - math.floor(#percentText / 2),
      centerY + 1,
      percentText,
      prism.Color4.WHITE
   )

   -- Draw phase description
   local phaseText = progress.phase
   self.overlayDisplay:print(
      centerX - math.floor(#phaseText / 2),
      centerY + 3,
      phaseText,
      prism.Color4.GRAY
   )

   -- Draw step counter
   local stepText = string.format("%d / %d steps", progress.current, progress.total)
   self.overlayDisplay:print(
      centerX - math.floor(#stepText / 2),
      centerY + 5,
      stepText,
      prism.Color4.DARKGRAY
   )

   -- Render to screen
   self.display:draw()
   self.overlayDisplay:draw()
end

function LoadingState:keypressed(key)
   -- Allow ESC to cancel (optional)
   if key == "escape" then
      self:getManager():pop()
   end
end

return LoadingState
