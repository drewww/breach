---@class TunnelAgent:Object
---@field position Vector2
---@field direction Vector2
---@field width integer
---@field stepsSinceLastFeature integer
---@field stepsSinceLastTurn integer
---@field alive boolean
---@field featureBag table<string> Bag of feature types ("junction", "turn", "end")
---@field junctionTypeBag table<string> Bag of junction types ("junction-continue")
---@field minStepsBeforeFeature integer Minimum steps before eligible for features
---@field minStepsBeforeTurn integer Minimum steps before eligible for turns
---@field worldSize Vector2? World dimensions used to clamp junction size to bounds

local TunnelAgent = prism.Object:extend("TunnelAgent")

MAX_FEATURES = 12
MIN_FEATURES = 3



--- Constructor for a new tunnel agent
---@param position Vector2 Starting position
---@param direction Vector2 Direction vector (will be normalized)
---@param width integer Width of the hallway (0=1-wide, 1=3-wide, 2=5-wide)
--- @param features integer a fixed number of features to budget for the agent, otherwise randomize within the range from MIN_FEATURES to MAX_FEATURES.
function TunnelAgent:__new(position, direction, width, features, worldSize)
   self.position = prism.Vector2(position.x, position.y)
   self.direction = direction:normalize():round()
   self.width = width or 2 -- Default to 5-wide hallways

   self.stepsSinceLastFeature = 0
   self.stepsSinceLastTurn = 0
   self.alive = true
   self.worldSize = worldSize

   -- Per spec: 8 steps minimum before features/turns
   self.minStepsBeforeFeature = 8
   self.minStepsBeforeTurn = 8

   -- Initialize budget tracking
   self:initializeBudget(features)
end

--- Initialize the agent's feature budget as bags of strings
--- @param features number Set the budget to exactly this number of features.
function TunnelAgent:initializeBudget(features)
   -- Set total number of features

   local totalFeatures = math.floor(RNG:random(MIN_FEATURES, MAX_FEATURES))

   if features and features > 0 then
      totalFeatures = features
   end

   -- Count how many of each feature type
   local junctionCount = 0
   local turnCount = 0
   local endCount = 0

   -- Randomly assign feature types
   for i = 1, totalFeatures do
      local roll = RNG:random(1, 100)
      if roll <= 50 then
         junctionCount = junctionCount + 1
      else
         turnCount = turnCount + 1
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

   -- insert only one "end"
   -- table.insert(self.featureBag, "end")

   prism.logger.info("FEATURES: ", totalFeatures, #self.featureBag)
   for _, feature in ipairs(self.featureBag) do
      prism.logger.info(feature)
   end

   -- Build the junction type bag with a random mix of junction types:
   -- 40% straight, 20% turn-left, 20% turn-right, 15% 3-way, 5% 4-way
   self.junctionTypeBag = {}
   for i = 1, junctionCount do
      local roll = RNG:random(1, 100)
      local jtype
      if roll <= 40 then
         jtype = "junction-continue"
      elseif roll <= 60 then
         jtype = "junction-turn-left"
      elseif roll <= 80 then
         jtype = "junction-turn-right"
      elseif roll <= 95 then
         jtype = "junction-3way"
      else
         jtype = "junction-4way"
      end
      table.insert(self.junctionTypeBag, jtype)
   end
end

--- @return integer the number of remaining features
function TunnelAgent:getRemainingBudget()
   prism.logger.info("remaining budget: ", #self.featureBag)
   return #self.featureBag
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
   local lookAheadDistance = 3 -- Per spec: 5 steps lookahead
   local isClear = self:checkAhead(builder, lookAheadDistance)

   if not isClear then
      prism.logger.info("obstruction ahead!")
      -- Phase 4: try to turn before terminating
      local canLeft = self:canTurn(builder, "left", true)
      local canRight = self:canTurn(builder, "right", true)

      prism.logger.info("turn? l: ", canLeft, " r: ", canRight)
      -- Build option list from valid turns only
      local options = {}
      if canLeft then table.insert(options, "left") end
      if canRight then table.insert(options, "right") end

      if #options == 0 then
         -- No valid turns available - terminate
         prism.logger.info("Collision: no valid turns, terminating.")
         self.alive = false
         return {}, false
      end

      -- Pick randomly from valid turns and fall through to dig/move
      local choice = options[RNG:random(1, #options)]
      prism.logger.info("Collision: turning " .. choice .. " to avoid obstacle.")
      self:applyTurn(builder, choice)
      -- (Phase 8 will add merge logic for remaining cases)
   end

   -- Dig at current position
   self:dig(builder)

   -- Move forward
   self.position = self.position + self.direction

   -- Increment step counters
   self.stepsSinceLastFeature = self.stepsSinceLastFeature + 1
   self.stepsSinceLastTurn = self.stepsSinceLastTurn + 1

   -- Check if we should execute a feature
   local newAgents = {}
   if self:shouldTriggerFeature() then
      newAgents = self:executeFeature(builder)
   end

   return newAgents, self.alive
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

         if not builder:inBounds(checkPos:decompose()) then
            prism.logger.info("found edge of world")
            return false
         end

         local cell = builder:get(checkPos.x, checkPos.y)
         if cell then
            -- Check if it's a floor (already dug)
            local nameComponent = cell:get(prism.components.Name)
            local isFloor = nameComponent and nameComponent.name == "Floor"

            if isFloor then
               -- Found existing tunnel ahead
               prism.logger.info("found floor, break")
               return false
            end
         else
            -- if there's nothing there, also return false
            return false
         end
      end
   end

   return true
end

--- Check if the agent is eligible for a feature (enough steps since last)
---@return boolean eligible
function TunnelAgent:isEligibleForFeature()
   return self.stepsSinceLastFeature >= self.minStepsBeforeFeature
end

--- Calculate the probability of a feature occurring this step
--- Per spec: Start at 2%, increase to 100% over 4*minimum distance steps
---@return number probability Value from 0.0 to 1.0
function TunnelAgent:calculateFeatureProbability()
   if not self:isEligibleForFeature() then
      return 0
   end

   -- How many steps past minimum?
   local stepsOverMinimum = self.stepsSinceLastFeature - self.minStepsBeforeFeature

   -- Ramp from 2% to 100% over (4 * minSteps) additional steps
   local rampSteps = self.minStepsBeforeFeature * 4
   local progress = math.min(stepsOverMinimum / rampSteps, 1.0)

   -- Linear interpolation from 0.02 to 1.0
   return 0.02 + (progress * 0.98)
end

--- Determine if a feature should trigger this step
---@return boolean shouldTrigger
function TunnelAgent:shouldTriggerFeature()
   -- Must have features left in the bag
   if #self.featureBag == 0 then
      return false
   end

   local probability = self:calculateFeatureProbability()
   return RNG:random() < probability
end

--- Pick a random feature from the bag and execute it
---@param builder LevelBuilder The level builder
---@return table newAgents List of new agents spawned
function TunnelAgent:executeFeature(builder)
   if #self.featureBag == 0 then
      return {}
   end

   -- Pick a random feature from the bag
   local featureIndex = RNG:random(1, #self.featureBag)
   local feature = self.featureBag[featureIndex]

   prism.logger.info("executing feature: ", feature)

   table.remove(self.featureBag, featureIndex)

   -- Reset steps since feature
   self.stepsSinceLastFeature = 0

   if feature == "turn" then
      return self:executeTurn(builder)
   elseif feature == "junction" then
      return self:executeJunction(builder)
   elseif feature == "end" then
      self.alive = false
      prism.logger.info("ending due to end feature")
      return {}
   end

   return {}
end

--- Check if a turn in the given direction is valid
---@param builder LevelBuilder The level builder
---@param turnDirection string "left" or "right"
---@return boolean valid
function TunnelAgent:canTurn(builder, turnDirection, bypassCooldown)
   -- Must have waited enough steps since last turn (unless bypassed for collision avoidance)
   if not bypassCooldown and self.stepsSinceLastTurn < self.minStepsBeforeTurn then
      return false
   end

   -- Calculate the new direction after turning
   local newDirection
   if turnDirection == "left" then
      -- Counter-clockwise: rotate 3 times clockwise
      newDirection = self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
   else
      -- Clockwise
      newDirection = self.direction:rotateClockwise()
   end

   -- Check if there's at least 8 clear steps in that direction.
   -- Start at self.width+1 to skip the agent's own corridor tiles, which
   -- inevitably overlap the first self.width cells of the new direction.
   local perpendicular = newDirection:rotateClockwise()
   for d = self.width + 1, self.width + 8 do
      local checkCenter = self.position + (newDirection * d)

      for w = -self.width, self.width do
         local checkPos = checkCenter + (perpendicular * w)
         local cell = builder:get(checkPos.x, checkPos.y)
         if cell then
            local nameComponent = cell:get(prism.components.Name)
            local isFloor = nameComponent and nameComponent.name == "Floor"
            if isFloor then
               return false
            end
         end
      end
   end

   return true
end

--- Apply a turn in the given direction: dig the rounding corner and rotate.
--- This is the low-level mechanic shared by both collision-triggered and
--- feature-triggered turns.
---@param builder LevelBuilder The level builder
---@param turnDirection string "left" or "right"
function TunnelAgent:applyTurn(builder, turnDirection)
   -- Dig forward `width` extra cells to round the inside corner
   for i = 1, self.width do
      self:dig(builder)

      self.position = self.position + self.direction
      prism.logger.info("dig forward to round corner")
   end

   self.position = self.position - self.direction * (self.width + 1)

   -- Rotate the direction vector
   if turnDirection == "left" then
      -- Counter-clockwise = three clockwise rotations
      self.direction = self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
   else
      -- Clockwise
      self.direction = self.direction:rotateClockwise()
   end

   -- Reset turn cooldown
   self.stepsSinceLastTurn = 0

   -- do width digs forward, updating position to "clear" the corner.
   for i = 1, self.width do
      self:dig(builder)
      self.position = self.position + self.direction
   end
end

--- Execute a turn feature (picks best available direction; re-queues if neither works).
---@param builder LevelBuilder The level builder
---@return table newAgents Always empty for turns
function TunnelAgent:executeTurn(builder)
   local canLeft = self:canTurn(builder, "left")
   local canRight = self:canTurn(builder, "right")

   if not canLeft and not canRight then
      -- Neither direction is clear – consume the feature and continue straight
      prism.logger.info("Turn feature: no valid direction, skipping.")
      return {}
   end

   local turnDirection
   if canLeft and canRight then
      turnDirection = RNG:random() < 0.5 and "left" or "right"
   elseif canLeft then
      turnDirection = "left"
   else
      turnDirection = "right"
   end

   prism.logger.info("Turn feature: turning " .. turnDirection .. ".")
   self:applyTurn(builder, turnDirection)
   return {}
end

--- Execute a junction feature
---@param builder LevelBuilder The level builder
---@return table newAgents List of new agents spawned from junction
function TunnelAgent:executeJunction(builder)
   -- Pick junction type from bag
   if #self.junctionTypeBag == 0 then
      -- No junction types left, just continue
      return {}
   end

   local junctionIndex = RNG:random(1, #self.junctionTypeBag)
   local junctionType = self.junctionTypeBag[junctionIndex]
   table.remove(self.junctionTypeBag, junctionIndex)

   -- Calculate junction size per spec: 70% +1-2, 20% +3-5, 10% +6-8
   local sizeRoll = RNG:random(1, 100)
   local extraSize
   if sizeRoll <= 70 then
      extraSize = RNG:random(1, 2)
   elseif sizeRoll <= 90 then
      extraSize = RNG:random(3, 5)
   else
      extraSize = RNG:random(6, 8)
   end

   -- Clamp extraSize so the junction stays within a 1-cell boundary of the world
   if self.worldSize then
      local maxHalf = math.min(
         self.position.x - 1,
         self.worldSize.x - 1 - self.position.x,
         self.position.y - 1,
         self.worldSize.y - 1 - self.position.y
      )
      local maxExtraSize = math.max(0, maxHalf - self.width)
      extraSize = math.min(extraSize, maxExtraSize)
   end

   -- Junction dimensions (hallway width + extra on each side)
   local junctionWidth = (self.width * 2 + 1) + extraSize * 2
   local junctionHeight = (self.width * 2 + 1) + extraSize * 2

   -- Dig out the junction centered on current position
   local halfW = math.floor(junctionWidth / 2)
   local halfH = math.floor(junctionHeight / 2)

   for dx = -halfW, halfW do
      for dy = -halfH, halfH do
         local cellPos = self.position + prism.Vector2(dx, dy)
         builder:set(cellPos.x, cellPos.y, prism.cells.Floor())
      end
   end

   -- Build the list of spawn positions and directions based on junction type.
   -- Directions for perpendicular exits:
   local leftDir = self.direction:rotateClockwise():rotateClockwise():rotateClockwise()
   local rightDir = self.direction:rotateClockwise()

   -- spawn is a list of { pos, dir } tables, one per new agent to create.
   local spawn = {}

   if junctionType == "junction-continue" then
      -- Straight through: one exit on the far side
      table.insert(spawn, {
         pos = self.position + (self.direction * (halfH + 1)),
         dir = self.direction,
      })
   elseif junctionType == "junction-turn-left" then
      -- One exit on the left perpendicular side
      table.insert(spawn, {
         pos = self.position + (leftDir * (halfW + 1)),
         dir = leftDir,
      })
   elseif junctionType == "junction-turn-right" then
      -- One exit on the right perpendicular side
      table.insert(spawn, {
         pos = self.position + (rightDir * (halfW + 1)),
         dir = rightDir,
      })
   elseif junctionType == "junction-3way" then
      -- Straight through + one random perpendicular exit
      table.insert(spawn, {
         pos = self.position + (self.direction * (halfH + 1)),
         dir = self.direction,
      })
      local sideDir = RNG:random() < 0.5 and leftDir or rightDir
      table.insert(spawn, {
         pos = self.position + (sideDir * (halfW + 1)),
         dir = sideDir,
      })
   elseif junctionType == "junction-4way" then
      -- Straight through + both perpendicular exits
      table.insert(spawn, {
         pos = self.position + (self.direction * (halfH + 1)),
         dir = self.direction,
      })
      table.insert(spawn, {
         pos = self.position + (leftDir * (halfW + 1)),
         dir = leftDir,
      })
      table.insert(spawn, {
         pos = self.position + (rightDir * (halfW + 1)),
         dir = rightDir,
      })
   end

   -- Give each spawned agent a random fraction of the remaining budget
   local budget = self:getRemainingBudget()
   local newAgents = {}
   for _, desc in ipairs(spawn) do
      local share = math.floor(budget * RNG:random())
      local newAgent = TunnelAgent(desc.pos, desc.dir, self.width, share, self.worldSize)
      table.insert(newAgents, newAgent)
   end

   -- This agent dies after creating a junction
   self.alive = false

   return newAgents
end

return TunnelAgent
