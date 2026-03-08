local LoadingState = spectrum.GameState:extend("LoadingState")

--- Creates a new LoadingState that runs world generation and displays progress
--- @param generator TunnelWorldGenerator The world generator to run
--- @param display Display The display to render to
--- @param overlayDisplay Display The overlay display for UI elements
function LoadingState:__new(generator, display, overlayDisplay, existingPlayer)
   spectrum.GameState.__new(self)

   self.generator = generator
   self.display = display
   self.overlayDisplay = overlayDisplay
   self.existingPlayer = existingPlayer
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
      local playState = PlayState(self.display, self.overlayDisplay, self.builder, self.existingPlayer)
      self:getManager():push(playState)
   end
end

function LoadingState:draw()
   -- Clear displays
   self.display:clear()
   self.overlayDisplay:clear()

   -- Get progress info from generator
   local progress = self.generator:getProgress()

   -- Center the text on screen (overlayDisplay is SCREEN_WIDTH * 4, SCREEN_HEIGHT * 2)
   local centerX = SCREEN_WIDTH * 2
   local centerY = SCREEN_HEIGHT

   -- Draw title
   local title = "GENERATING FACILITY"
   self.overlayDisplay:print(
      centerX - math.floor(#title / 2),
      centerY - 3,
      title,
      prism.Color4.WHITE
   )

   -- Draw progress bar
   -- local barWidth = 20
   -- -- local barX = centerX / 2 - math.floor(barWidth / 2)
   -- local barX = 0
   -- local barY = centerY - 4
   -- -- Double the progress and clamp at 100% for display
   -- local displayProgress = math.min((progress.current / progress.total) * 5, 1.0)
   -- local fillWidth = math.floor(displayProgress * barWidth)
   -- -- Ensure at least 1 cell is filled if there's any progress
   -- if progress.current > 0 and fillWidth == 0 then
   --    fillWidth = 1
   -- end

   -- -- Draw bar background
   -- for i = 0, barWidth - 1 do
   --    self.overlayDisplay:print(barX + i, barY, " ", prism.Color4.GRAY)
   -- end

   -- Draw bar fill
   -- for i = 0, fillWidth - 1 do
   --    self.overlayDisplay:print(barX + i, barY, " ", prism.Color4.CYAN, prism.Color4.CYAN)
   -- end

   -- Draw percentage (doubled and clamped)
   local displayPercentage = math.min(progress.percentage * 4.2, 100)
   local percentText = string.format("%d%%", displayPercentage)
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
