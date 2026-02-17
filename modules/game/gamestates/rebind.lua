local controls = require "controls"
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
   { key = "use",            display = "Use" },
   { key = "cycle",          display = "Cycle" },
   { key = "reload",         display = "Reload" },
   { key = "dash_mode",      display = "Dash Mode" },
   { key = "dismiss",        display = "Dismiss" },
}

local TEMPLATE = "[   x    ]"
local WIDTH = 11
local OFFSET = 5
local PADDING_X = 4
local PADDING_Y = 3

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
end

function RebindState:update(dt)
   controls:update()

   if self.pressed then
      self.pressed = false
      return
   end

   -- Handle mouse hover to update grid position
   if not self.active then
      local mx, my = love.mouse.getPosition()
      local cellX, cellY = self.overlayDisplay:getCellUnderMouse(mx, my)

      -- Check if mouse is over a binding cell
      for i = 1, #self.list do
         local rowY = i + PADDING_Y
         if cellY == rowY then
            -- Check each of the 3 binding slots
            for x = 1, 3 do
               local startX = PADDING_X + OFFSET + x + (x * WIDTH)
               local endX = startX + WIDTH - 1
               if cellX >= startX and cellX <= endX then
                  self.position = prism.Vector2(x, i)
                  break
               end
            end
         end
      end
   end

   -- Handle mouse clicks
   if spectrum.Input.mouse[1].pressed and not self.active then
      self.active = true
   end

   if not self.active and controls.move.pressed then
      self.position = self.position + controls.move.vector
      if self.position.x < 1 then
         self.position.x = 3
      elseif self.position.x > 3 then
         self.position.x = 1
      end
      if self.position.y < 1 then
         self.position.y = #self.list
      elseif self.position.y > #self.list then
         self.position.y = 1
      end
   end

   if spectrum.Input.key["return"].pressed then self.active = true end

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
      self.pressed = true
      self.active = false
      if key == "escape" then return end
      self.grid:set(self.position.x, self.position.y, key)
      local config = {}
      for x = 1, 3 do
         local value = self.grid:get(x, self.position.y)
         if value and value ~= "" then
            table.insert(config, value)
         end
      end
      for x, y, value in self.grid:each() do
         if value == key and not self.position:equals(x, y) then self.grid:set(x, y, "") end
      end
      controls:setControl(self.list[self.position.y].key, config)
   end
end

function RebindState:draw()
   self.display:clear()
   self.overlayDisplay:clear()
   self.display:print(1, 1, "CONTROLS")
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

      if i == self.position.y then
         self.overlayDisplay:print(PADDING_X, i + PADDING_Y, controlDef.display,
            prism.Color4.BLUE)
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
         if self.position:equals(x, i) then
            for xi = PADDING_X + OFFSET + x + (x * WIDTH), PADDING_X + OFFSET + x + (x * WIDTH) + WIDTH - 1 do
               self.overlayDisplay:putBG(xi, i + PADDING_Y, prism.Color4.BLUE)
            end
         end
      end
   end
   if self.active then self.overlayDisplay:print(PADDING_X, #self.list + 4 + PADDING_Y, "PRESS NEW KEY") end
   self.display:draw()
   self.overlayDisplay:draw()
end

function RebindState:unload()
   prism.logger.info("writing out controls.json: ", prism.json.encode(controls._config))
   controls:save()
end

return RebindState
