local controls = require "controls"
local Audio = require "audio"

--- @class RebindState : GameState
--- @field display Display
--- @overload fun(): RebindState
local RebindState = spectrum.GameState:extend "RebindState"

-- Hardcoded order for control display with human-readable names
-- Update this list when adding new controls to controls.lua
local CONTROL_ORDER = {
   -- Movement controls (grouped together)
   { key = "move_upleft",    display = "Move NW" },
   { key = "move_up",        display = "Move N" },
   { key = "move_upright",   display = "Move NE" },
   { key = "move_left",      display = "Move W" },
   { key = "move_right",     display = "Move E" },
   { key = "move_downleft",  display = "Move SW" },
   { key = "move_down",      display = "Move S" },
   { key = "move_downright", display = "Move SE" },

   -- Action controls
   { key = "wait",           display = "Wait" },
   { key = "use",            display = "Use Item" },
   { key = "reload",         display = "Reload" },
   { key = "dash_mode",      display = "Dash" },
   { key = "dismiss",        display = "Dismiss" },

   { key = "drop",           display = "Drop" },
   { key = "consume",        display = "Extract" },


   { key = "slot1",          display = "Activate Slot 1" },
   { key = "slot2",          display = "Activate Slot 2" },
   { key = "slot3",          display = "Activate Slot 3" },
   { key = "slot4",          display = "Activate Slot 4" },
   { key = "slot5",          display = "Activate Slot 5" },
   { key = "slot6",          display = "Activate Slot 6" },
}

local TEMPLATE = "[   x    ]"
local WIDTH = 11
local OFFSET = 5
local PADDING_X = 4
local PADDING_Y = 3

-- Right column settings
local RIGHT_COLUMN_X = 60
local RIGHT_COLUMN_START_Y = PADDING_Y + 2

-- Audio settings
local AUDIO_LEVELS = {
   { name = "Off",  volume = 0.0 },
   { name = "Low",  volume = 0.3 },
   { name = "Med",  volume = 0.5 },
   { name = "High", volume = 0.9 },
}

function RebindState:load(previous)
   self.display = previous.display
   self.overlayDisplay = previous.overlayDisplay
   local height = 0
   self.grid = prism.SparseGrid()
   self.list = {}

   local controlsConfig = controls:getConfig().controls

   -- Use the predefined order
   for _, controlDef in ipairs(CONTROL_ORDER) do
      local name = controlDef.key
      local inputs = controlsConfig[name]
      if inputs then
         height = height + 1
         if type(inputs) == "table" then
            for i = 1, 3 do
               self.grid:set(i, height, inputs[i] or "")
            end
         else
            self.grid:set(1, height, inputs)
            self.grid:set(2, height, "")
            self.grid:set(3, height, "")
         end
         table.insert(self.list, { key = name, display = controlDef.display })
      end
   end

   self.position = prism.Vector2(1, 1)
   self.inRightColumn = false

   -- Initialize audio settings
   local currentVolume = Audio.getMasterVolume()
   self.audioLevelIndex = 3 -- Default to Med
   for i, level in ipairs(AUDIO_LEVELS) do
      if math.abs(currentVolume - level.volume) < 0.05 then
         self.audioLevelIndex = i
         break
      end
   end
end

function RebindState:update(dt)
   controls:update()

   if self.pressed then
      self.pressed = false
      return
   end

   -- Handle mouse hover to update grid position and clicks
   if not self.active then
      local mx, my = love.mouse.getPosition()
      local cellX, cellY = self.overlayDisplay:getCellUnderMouse(mx, my)

      local overValidCell = false

      -- Check if mouse is over a binding cell (left column)
      for i = 1, #self.list do
         local rowY = i + PADDING_Y
         if cellY == rowY then
            -- Check each of the 3 binding slots
            for x = 1, 3 do
               local startX = PADDING_X + OFFSET + x + (x * WIDTH)
               local endX = startX + WIDTH - 1
               if cellX >= startX and cellX <= endX then
                  self.position = prism.Vector2(x, i)
                  self.inRightColumn = false
                  overValidCell = true
                  break
               end
            end
         end
      end

      -- Check if mouse is over audio controls (right column)
      for i = 1, 4 do
         local audioY = RIGHT_COLUMN_START_Y + i
         local audioBoxStartX = RIGHT_COLUMN_X
         local audioBoxEndX = audioBoxStartX + WIDTH - 1
         if cellY == audioY and cellX >= audioBoxStartX and cellX <= audioBoxEndX then
            self.audioLevelIndex = i
            self.inRightColumn = true
            overValidCell = true
            break
         end
      end

      -- Handle mouse clicks
      if spectrum.Input.mouse[1].pressed and overValidCell then
         if self.inRightColumn then
            -- Change audio level
            Audio.setMasterVolume(AUDIO_LEVELS[self.audioLevelIndex].volume)
            Audio.playSelect()
         else
            self.active = true
         end
      end
   end

   if not self.active and controls.move.pressed then
      local moveVector = controls.move.vector

      if self.inRightColumn then
         -- In right column (audio controls)
         if moveVector.y ~= 0 then
            -- Move up/down in audio options
            self.audioLevelIndex = self.audioLevelIndex + moveVector.y
            if self.audioLevelIndex < 1 then
               self.audioLevelIndex = 4
            elseif self.audioLevelIndex > 4 then
               self.audioLevelIndex = 1
            end
         elseif moveVector.x < 0 then
            -- Move left to control bindings
            self.inRightColumn = false
            self.position = prism.Vector2(3, math.min(self.position.y, #self.list))
         end
      else
         -- In left column (control bindings)
         self.position = self.position + moveVector

         -- Handle horizontal navigation
         if self.position.x < 1 then
            self.position.x = 3
         elseif self.position.x > 3 then
            -- Move to right column
            self.inRightColumn = true
         end

         -- Handle vertical wrapping
         if self.position.y < 1 then
            self.position.y = #self.list
         elseif self.position.y > #self.list then
            self.position.y = 1
         end
      end
   end

   if spectrum.Input.key["return"].pressed then
      if self.inRightColumn then
         -- Select audio level
         Audio.setMasterVolume(AUDIO_LEVELS[self.audioLevelIndex].volume)
         Audio.playSelect()
      else
         self.active = true
      end
   end

   if spectrum.Input.key["escape"].pressed then
      if self.active then
         self.active = false
      else
         self.manager:pop()
      end
   end
end

function RebindState:keypressed(key)
   if self.active then
      self:bindInput(key)
   end
end

function RebindState:mousepressed(x, y, button)
   if self.active then
      self:bindInput("mouse:" .. button)
   end
end

function RebindState:bindInput(input)
   self.pressed = true
   self.active = false
   if input == "escape" then return end
   self.grid:set(self.position.x, self.position.y, input)
   local config = {}
   for x = 1, 3 do
      local value = self.grid:get(x, self.position.y)
      if value and value ~= "" then
         table.insert(config, value)
      end
   end
   for x, y, value in self.grid:each() do
      if value == input and not self.position:equals(x, y) then self.grid:set(x, y, "") end
   end
   controls:setControl(self.list[self.position.y].key, config)
end

function RebindState:draw()
   self.display:clear()
   self.overlayDisplay:clear()

   -- Title
   self.display:print(1, 1, "SETTINGS")

   -- Draw control bindings (left column)
   for i, controlDef in ipairs(self.list) do
      self.overlayDisplay:print(PADDING_X, i + PADDING_Y, controlDef.display)
      local hasAnyBinding = false
      for x = 1, 3 do
         local value = self.grid:get(x, i)
         if value and value ~= "" then
            hasAnyBinding = true
            break
         end
      end

      if not hasAnyBinding then
         self.overlayDisplay:print(PADDING_X, i + PADDING_Y, controlDef.display, prism.Color4.RED)
      end

      if not self.inRightColumn and i == self.position.y then
         self.overlayDisplay:print(PADDING_X, i + PADDING_Y, controlDef.display, prism.Color4.BLUE)
      end

      for x = 1, 3 do
         local value = self.grid:get(x, i) or ""
         self.overlayDisplay:print(PADDING_X + OFFSET + x + (x * WIDTH), i + PADDING_Y, "[", nil, nil, nil, "left",
            WIDTH)
         self.overlayDisplay:print(PADDING_X + OFFSET + x + (x * WIDTH), i + PADDING_Y, value, nil, nil,
            nil,
            "center",
            WIDTH)
         self.overlayDisplay:print(PADDING_X + OFFSET + x + (x * WIDTH), i + PADDING_Y, "]", nil, nil, nil, "right",
            WIDTH)
         if not self.inRightColumn and self.position:equals(x, i) then
            for xi = PADDING_X + OFFSET + x + (x * WIDTH), PADDING_X + OFFSET + x + (x * WIDTH) + WIDTH - 1 do
               self.overlayDisplay:putBG(xi, i + PADDING_Y, prism.Color4.BLUE)
            end
         end
      end
   end

   -- Draw right column header
   self.overlayDisplay:print(RIGHT_COLUMN_X, RIGHT_COLUMN_START_Y, "VOLUME")

   -- Draw all 4 audio level boxes in right column
   for i, level in ipairs(AUDIO_LEVELS) do
      local audioY = RIGHT_COLUMN_START_Y + i

      -- Draw box
      self.overlayDisplay:print(RIGHT_COLUMN_X, audioY, "[", nil, nil, nil, "left", WIDTH)
      self.overlayDisplay:print(RIGHT_COLUMN_X, audioY, level.name, nil, nil, nil, "center", WIDTH)
      self.overlayDisplay:print(RIGHT_COLUMN_X, audioY, "]", nil, nil, nil, "right", WIDTH)

      -- Highlight cursor position with blue if in right column on this level
      -- Otherwise highlight the active level with green
      if self.inRightColumn and i == self.audioLevelIndex then
         -- Blue for cursor position
         for xi = RIGHT_COLUMN_X, RIGHT_COLUMN_X + WIDTH - 1 do
            self.overlayDisplay:putBG(xi, audioY, prism.Color4.BLUE)
         end
      elseif i == self.audioLevelIndex then
         -- Green for active level (when cursor is elsewhere)
         for xi = RIGHT_COLUMN_X, RIGHT_COLUMN_X + WIDTH - 1 do
            self.overlayDisplay:putBG(xi, audioY, prism.Color4.GREEN)
         end
      end
   end

   if self.active then
      self.overlayDisplay:print(PADDING_X, #self.list + 4 + PADDING_Y, "PRESS NEW KEY")
   end

   self.display:draw()
   self.overlayDisplay:draw()
end

function RebindState:unload()
   prism.logger.info("writing out controls.json: ", prism.json.encode(controls._config))
   controls:save()
   Audio.save()
end

return RebindState
