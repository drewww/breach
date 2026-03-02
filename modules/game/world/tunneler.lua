---@class Tunneler:Object
---@field width integer
---@field direction Vector2
--- @field position Vector2

local Tunneler = prism.Object:extend("Tunneler")


function Tunneler:__new(position, direction)
   self.width = 3

   -- ensure the direction is a unit vector
   self.direction = direction:normalize():round()

   self.position = position
end

function Tunneler:step(builder)
   -- each step, move forward one and dig out a "width" tunnel.

   local perpandicular = self.direction:rotateClockwise()

   local from = self.position - (perpandicular * self.width)
   local to = self.position + (perpandicular * self.width)

   builder:line(from.x, from.y, to.x, to.y, prism.cells.Floor)

   self.position = self.position + self.direction
   prism.logger.info("tunneler: ", self.position)
end

return Tunneler
