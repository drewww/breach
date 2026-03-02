---@class TunnelAgent:Object
---@field position Vector2
---@field direction Vector2
---@field width integer
---@field stepsSinceLastFeature integer
---@field stepsSinceLastTurn integer
---@field alive boolean
---@field featureBag table<string> Bag of feature types ("junction", "turn", "end")
---@field junctionTypeBag table<string> Bag of junction types ("junction-continue")

local TunnelAgent = prism.Object:extend("TunnelAgent")

--- Constructor for a new tunnel agent
---@param position Vector2 Starting position
---@param direction Vector2 Direction vector (will be normalized)
---@param width integer Width of the hallway (0=1-wide, 1=3-wide, 2=5-wide)
function TunnelAgent:__new(position, direction, width)
   self.position = prism.Vector2(position.x, position.y)
   self.direction = direction:normalize():round()
   self.width = width or 2 -- Default to 5-wide hallways

   self.stepsSinceLastFeature = 0
   self.stepsSinceLastTurn = 0
   self.alive = true

   -- Initialize budget tracking
   self:initializeBudget()
end

--- Initialize the agent's feature budget as bags of strings
function TunnelAgent:initializeBudget()
   -- Decide total number of features (5-15)
   local totalFeatures = love.math.random(5, 15)

   -- Count how many of each feature type
   local junctionCount = 0
   local turnCount = 0
   local endCount = 0

   -- Randomly assign feature types
   for i = 1, totalFeatures do
      local roll = love.math.random(1, 100)
      if roll <= 40 then     -- 40% junction
         junctionCount = junctionCount + 1
      elseif roll <= 80 then -- 40% turn
         turnCount = turnCount + 1
      else                   -- 20% end
         endCount = endCount + 1
      end
   end

   -- Build the feature bag
   self.featureBag = {}
   for i = 1, junctionCount do
      table.insert(self.featureBag, "junction")
   end
   for i = 1, turnCount do
      table.insert(self.featureBag, "turn")
   end
   for i = 1, endCount do
      table.insert(self.featureBag, "end")
   end

   -- Build the junction type bag (all "junction-continue" for now)
   self.junctionTypeBag = {}
   for i = 1, junctionCount do
      table.insert(self.junctionTypeBag, "junction-continue")
   end
end

--- Check if the agent has a specific feature available
---@param featureType string Type of feature ("junction", "turn", "end")
---@return boolean
function TunnelAgent:hasFeature(featureType)
   for _, feature in ipairs(self.featureBag) do
      if feature == featureType then
         return true
      end
   end
   return false
end

--- Consume a feature from the bag
---@param featureType string Type of feature to consume
---@return boolean success True if feature was consumed
function TunnelAgent:consumeFeature(featureType)
   for i, feature in ipairs(self.featureBag) do
      if feature == featureType then
         table.remove(self.featureBag, i)
         return true
      end
   end
   return false
end

--- Check if the agent has a specific junction type available
---@param junctionType string Type of junction ("junction-continue", etc.)
---@return boolean
function TunnelAgent:hasJunctionType(junctionType)
   for _, jtype in ipairs(self.junctionTypeBag) do
      if jtype == junctionType then
         return true
      end
   end
   return false
end

--- Consume a junction type from the bag
---@param junctionType string Type of junction to consume
---@return boolean success True if junction type was consumed
function TunnelAgent:consumeJunctionType(junctionType)
   for i, jtype in ipairs(self.junctionTypeBag) do
      if jtype == junctionType then
         table.remove(self.junctionTypeBag, i)
         return true
      end
   end
   return false
end

--- Step the agent forward one tile
---@param builder LevelBuilder The level builder to dig into
---@return table newAgents List of new agents spawned (empty for now)
---@return boolean shouldContinue Whether this agent should continue
function TunnelAgent:step(builder)
   if not self.alive then
      return {}, false
   end

   -- Check ahead for collisions before digging
   local lookAheadDistance = 5 -- Per spec: 5 steps lookahead
   local isClear = self:checkAhead(builder, lookAheadDistance)

   if not isClear then
      -- Collision detected - for now, just terminate
      -- (Phase 4 will add turn logic, Phase 8 will add merge logic)
      self.alive = false
      return {}, false
   end

   -- Dig at current position
   self:dig(builder)

   -- Move forward
   self.position = self.position + self.direction

   -- Increment step counters
   self.stepsSinceLastFeature = self.stepsSinceLastFeature + 1
   self.stepsSinceLastTurn = self.stepsSinceLastTurn + 1

   return {}, self.alive
end

--- Dig out the current position with the agent's width
--- Width 0 = 1-wide, width 1 = 3-wide, width 2 = 5-wide
---@param builder LevelBuilder The level builder to dig into
function TunnelAgent:dig(builder)
   local perpendicular = self.direction:rotateClockwise()

   -- Draw a line perpendicular to direction, centered on position
   local from = self.position - (perpendicular * self.width)
   local to = self.position + (perpendicular * self.width)

   builder:line(from.x, from.y, to.x, to.y, prism.cells.Floor)
end

--- Check ahead for collisions with existing tunnels
--- Checks a rectangle ahead: width of the hallway, depth of distance
---@param builder LevelBuilder The level builder to check
---@param distance integer How far ahead to check
---@return boolean clear True if the path is clear
function TunnelAgent:checkAhead(builder, distance)
   local perpendicular = self.direction:rotateClockwise()

   -- Check each cell in the rectangle ahead
   for d = 1, distance do
      local checkCenter = self.position + (self.direction * d)

      -- Check across the full width
      for w = -self.width, self.width do
         local checkPos = checkCenter + (perpendicular * w)

         local cell = builder:get(checkPos.x, checkPos.y)
         if cell then
            -- Check if it's a floor (already dug)
            local nameComponent = cell:get(prism.components.Name)
            local isFloor = nameComponent and nameComponent.name == "Floor"

            if isFloor then
               -- Found existing tunnel ahead
               return false
            end
         end
      end
   end

   return true
end

--- Evaluate and build list of available options for this agent
---@param builder LevelBuilder The level builder
---@param terminationPressure number Value from 0.0 to 1.0 indicating pressure to terminate
---@return table options List of option strings
function TunnelAgent:evaluateOptions(builder, terminationPressure)
   -- TODO: Implement in Phase 5
   return { "continue" }
end

return TunnelAgent
