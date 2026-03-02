---@class Tunneler:Object
---@field width integer
---@field direction Vector2
--- @field position Vector2

local Tunneler = prism.Object:extend("Tunneler")


function Tunneler:__new(position, direction, width)
   -- width of 1 means 1 on either side, so effective width of 3. we're not going to
   -- worry about making even-width halls.
   self.width = width or 2

   -- ensure the direction is a unit vector
   self.direction = direction:normalize():round()

   self.turnOdds = 0.05
   self.splitOdds = 0.02
   self.deadEndOdds = 0.005

   self.position = position
end

--- @return table agents, boolean shouldContinue
function Tunneler:step(builder)
   -- each step, move forward one and dig out a "width" tunnel.

   self:dig(builder)

   -- Check ahead for existing tunnels
   local lookAheadDistance = self.width * 2
   local shouldContinue = self:checkAhead(builder, lookAheadDistance)
   if not shouldContinue then
      return {}, false
   end

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

   local children = {}
   if RNG:random() < self.splitOdds then
      -- decide on split type.
      prism.logger.info("SPLIT")
      local splits = { "junction", "left", "left", "right", "right" }

      local split = splits[RNG:random(1, #splits)]

      local width = RNG:random(0, self.width + 1)

      if split == "junction" then
         -- Create two child tunnelers, one rotating left and one rotating right
         local leftDir = self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
         local rightDir = self.direction:rotateClockwise()

         table.insert(children, Tunneler(prism.Vector2(self.position:decompose()), leftDir, width))
         table.insert(children, Tunneler(prism.Vector2(self.position:decompose()), rightDir, width))
      elseif split == "left" then
         -- Create one child tunneler rotating left (counter-clockwise)
         local leftDir = self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
         table.insert(children, Tunneler(prism.Vector2(self.position:decompose()), leftDir, width))
      elseif split == "right" then
         -- Create one child tunneler rotating right (clockwise)
         local rightDir = self.direction:rotateClockwise()
         table.insert(children, Tunneler(prism.Vector2(self.position:decompose()), rightDir, width))
      end
   end

   self.position = self.position + self.direction

   return children, true
end

function Tunneler:dig(builder)
   local perpandicular = self.direction:rotateClockwise()

   local from = self.position - (perpandicular * self.width)
   local to = self.position + (perpandicular * self.width)

   builder:line(from.x, from.y, to.x, to.y, prism.cells.Floor)
end

--- Check ahead for existing tunnels and decide how to respond
--- @return boolean shouldContinue Whether the tunneler should continue
function Tunneler:checkAhead(builder, lookAheadDistance)
   local checkPos = self.position + (self.direction * lookAheadDistance)

   -- Check if the lookahead position has already been dug out
   local cell = builder:get(checkPos.x, checkPos.y)
   if not cell then
      -- Out of bounds or no cell data
      return true
   end

   -- Check if it's a floor (already dug)
   local nameComponent = cell:get(prism.components.Name)
   local isFloor = nameComponent and nameComponent.name == "Floor"

   if isFloor then
      -- We're approaching an existing tunnel, decide what to do
      local actions = { "end", "end", "merge", "merge", "merge", "turn", "turn" }
      local action = actions[RNG:random(1, #actions)]

      if action == "end" then
         -- Simply stop this tunneler
         prism.logger.debug("Tunneler ending (approaching existing tunnel)")
         return false
      elseif action == "merge" then
         -- Break through the walls between us and merge
         prism.logger.debug("Tunneler merging with existing tunnel")
         local mergePos = self.position
         for i = 1, lookAheadDistance do
            mergePos = mergePos + self.direction
            self.position = mergePos
            self:dig(builder)
         end
         return false -- End after merging
      elseif action == "turn" then
         -- Turn to avoid the tunnel
         prism.logger.debug("Tunneler turning to avoid existing tunnel")
         self.direction = RNG:random() <= 0.5 and self.direction:rotateClockwise() or
             self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
         return true
      end
   end

   return true
end

return Tunneler
