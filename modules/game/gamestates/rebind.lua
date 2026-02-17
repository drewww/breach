local controls = require "controls"
--- @class RebindState : GameState
--- @field display Display
--- @overload fun(): RebindState
local RebindState = spectrum.GameState:extend "RebindState"

function RebindState:load(previous)
   self.display = previous.display
   self.overlayDisplay = previous.overlayDisplay
   local height = 0
   self.grid = prism.SparseGrid()
   self.list = {}
   for name, inputs in pairs(controls:getConfig().controls) do
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
      table.insert(self.list, name)
   end
   self.position = prism.Vector2(1, 1)
end

function RebindState:update(dt)
   controls:update()

   if self.pressed then
      self.pressed = false
      return
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
      controls:setControl(self.list[self.position.y], config)
   end
end

local TEMPLATE = "[   x    ]"
local WIDTH = 11
local OFFSET = 10
local PADDING_X = 4
local PADDING_Y = 3

function RebindState:draw()
   self.display:clear()
   self.overlayDisplay:clear()
   self.display:print(1, 1, "CONTROLS")
   for i, name in ipairs(self.list) do
      self.overlayDisplay:print(PADDING_X, i + PADDING_Y, name)
      local hasAnyBinding = false
      for x = 1, 3 do
         local value = self.grid:get(x, i)
         if value and value ~= "" then
            hasAnyBinding = true
            break
         end
      end

      if not hasAnyBinding then
         self.overlayDisplay:print(PADDING_X, i + PADDING_Y, name, prism.Color4.RED)
      end

      if i == self.position.y then self.overlayDisplay:print(PADDING_X, i + PADDING_Y, name, prism.Color4.BLUE) end

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
