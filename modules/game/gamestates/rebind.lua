local controls = require "controls"
--- @class RebindState : GameState
--- @field display Display
--- @overload fun(): RebindState
local RebindState = spectrum.GameState:extend "RebindState"

function RebindState:load(previous)
   self.display = previous.display
   local height = 0
   self.grid = prism.SparseGrid()
   self.list = {}
   for name, inputs in pairs(controls:getConfig().controls) do
      height = height + 1
      if type(inputs) == "table" then
         for i, input in ipairs(inputs) do
            self.grid:set(i, height, input)
         end
      else
         self.grid:set(1, height, inputs)
         self.grid:set(2, height, "")
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
      if not self.grid:get(self.position:decompose()) then
         if controls.move.vector.y > 0 then
            self.position = prism.Vector2(self.position.x, 1)
         elseif controls.move.vector.y < 0 then
            self.position = prism.Vector2(self.position.x, #self.list)
         elseif controls.move.vector.x > 0 then
            self.position.x = 1
         elseif controls.move.vector.x < 0 then
            self.position.x = 2
         end
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
      local x = 1
      while self.grid:get(x, self.position.y) do
         table.insert(config, self.grid:get(x, self.position.y))
         x = x + 1
      end
      for x, y, value in self.grid:each() do
         if value == key and not self.position:equals(x, y) then self.grid:set(x, y, "") end
      end
      controls:setControl(self.list[self.position.y], config)
   end
end

local TEMPLATE = "[   x    ]"
local WIDTH = 11

function RebindState:draw()
   self.display:clear()
   self.display:print(1, 1, "Rebinding controls!")
   for i, name in ipairs(self.list) do
      self.display:print(1, i + 2, name)
      local x = 1
      if self.grid:get(1, i) == "" and self.grid:get(2, i) == "" then
         self.display:print(1, i + 2, name, prism.Color4.RED)
      end

      if i == self.position.y then self.display:print(1, i + 2, name, prism.Color4.BLUE) end
      while self.grid:get(x, i) do
         self.display:print(10 + x + (x * WIDTH), i + 2, "[", nil, nil, nil, "left", WIDTH)
         self.display:print(10 + x + (x * WIDTH), i + 2, self.grid:get(x, i), nil, nil, nil, "center", WIDTH)
         self.display:print(10 + x + (x * WIDTH), i + 2, "]", nil, nil, nil, "right", WIDTH)
         if self.position:equals(x, i) then
            for xi = 10 + x + (x * WIDTH), 10 + x + (x * WIDTH) + WIDTH - 1 do
               self.display:putBG(xi, i + 2, prism.Color4.BLUE)
            end
         end
         -- self.display:print(20 + x + (x * 12), i + 2, "]")
         x = x + 1
      end
   end
   if self.active then self.display:print(1, #self.list + 4, "Enter a key to rebind!") end
   self.display:draw()
end

function RebindState:unload()
   love.filesystem.write("controls.json", prism.json.encode(controls._config))
end

return RebindState
