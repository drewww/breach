---@class Tunneler:Object
---@field width integer
---@field direction Vector2
--- @field position Vector2

local Tunneler = prism.Object:extend("Tunneler")


function Tunneler:__new(position, direction)
   -- width of 1 means 1 on either side, so effective width of 3. we're not going to
   -- worry about making even-width halls.
   self.width = 1

   -- ensure the direction is a unit vector
   self.direction = direction:normalize():round()

   self.turnOdds = 0.05
   self.splitOdds = 0.05

   self.position = position
end

--- @return table agents
function Tunneler:step(builder)
   -- each step, move forward one and dig out a "width" tunnel.

   self:dig(builder)

   -- some chance of rotating
   if RNG:random() < self.turnOdds then
      -- silly but whatever
      --
      -- when we rotate, we need to step forward N times to clear out the corner. where N is the width.

      local corner = prism.Vector2(self.position:decompose())

      for i = 1, self.width do
         self.position = self.position + self.direction
         self:dig(builder)
      end

      self.position = corner

      self.direction = RNG:random() <= 0.5 and self.direction:rotateClockwise() or
          self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
   end

   self.position = self.position + self.direction

   return {}
end

function Tunneler:dig(builder)
   local perpandicular = self.direction:rotateClockwise()

   local from = self.position - (perpandicular * self.width)
   local to = self.position + (perpandicular * self.width)

   builder:line(from.x, from.y, to.x, to.y, prism.cells.Floor)
end

return Tunneler
