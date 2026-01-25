RULES = {}

DASH_DISTANCE = 2
DASH_NEIGHBORHOOD = prism.Vector2.neighborhood4

GRENADE_MINIMUM_ARM_DISTANCE = 3

-- returns a set of valid destination vectors, mapped to moves. so it's
-- neighborhood4 as the keys, and values for where that result would get you.
-- all normalized to 0,0? not actor position.

--- @param level Level
--- @param actor Actor
--- @return table<Vector2, Vector2> A table where the keys are the neighborhood4 vectors, and the values are the farthest you can dash in that direction. The values are relative to actor position, not global
function RULES.dashLocations(level, actor)
   -- first, create the base keys. for now, we're doing neighborhood4 as options.
   local results = {}

   local inputs = DASH_NEIGHBORHOOD

   local mover = actor:expect(prism.components.Mover)

   for _, dir in ipairs(inputs) do
      -- check how far we can go in that direction.
      -- can we generalize this for multiple steps?
      -- we want to return the farthes possible step in each direction.
      local farthestDirection = nil

      local allPassable = true
      for distance = 1, DASH_DISTANCE, 1 do
         local dest = actor:getPosition() + dir * distance

         if level:inBounds(dest.x, dest.y) and level:getCellPassableByActor(dest.x, dest.y, actor, mover.mask) then
            if allPassable then
               farthestDirection = dest
            end
         else
            allPassable = false
         end
      end

      if farthestDirection then
         results[dir] = farthestDirection
      end
   end

   return results
end

--- @class PushResult
--- @field pos Vector2 The resulting position in world coordinates.
--- @field direction Vector2 The actor-relative direction of the push. For subsequent steps, this is expressed relative to the previous step, not relative to the starting position.
--- @field collision boolean

---Calculates the result of a push.
--- TODO Figure out if floating point push is acceptable.
--- TODO Consider switching to a full Damage type in the future.
---@param actor Actor The actor being pushed.
---@param vector Vector2 The direction of the push. Can be any unit vector.
---@param push integer The push "power." push=1 should push one space.
--- @return PushResult[], number
function RULES.pushResult(level, actor, vector, push)
   local results = {}
   local pos = actor:getPosition()

   --- TODO we need to check on the vector in.
   vector = vector:normalize()

   -- Calculate each step of the push
   local totalSteps = 0
   for step = 1, push do
      ---@type Vector2
      local nextPos = pos + (vector * step)
      -- round vector
      nextPos.x = math.floor(nextPos.x + 0.5)
      nextPos.y = math.floor(nextPos.y + 0.5)

      local collision = false
      local mask = prism.Collision.createBitmaskFromMovetypes({ "walk" })

      -- Check if the target position is valid
      if not level:inBounds(nextPos.x, nextPos.y) then
         collision = true
      elseif not level:getCellPassableByActor(nextPos.x, nextPos.y, actor, mask) then
         collision = true
      end

      local lastPos = actor:getPosition()
      if step > 1 then
         lastPos = results[step - 1].pos
      end

      -- Create push result for this step
      local pushResult = {
         pos = nextPos,
         direction = nextPos - lastPos,
         collision = collision
      }

      table.insert(results, pushResult)

      if collision then
         break
      else
         totalSteps = totalSteps + 1
      end
      -- -- If we hit a collision, STOP
      -- if collision then
      --    -- Fill remaining steps with collision results at the same position
      --    f  or remainingStep = step + 1, push do
      --       table.insert(results, {
      --          pos = nextPos,
      --          collision = true
      --       })
      --    end
      --    break
      -- end
   end

   return results, totalSteps
end

--- @class BounceResult
--- @field pos Vector2
--- @field distance number
--- @field bounce boolean

-- Helper function to determine wall type based on local context and approach direction
local function getWallType(level, tx, ty, fromX, fromY)
   local mask = prism.Collision.createBitmaskFromMovetypes({ "fly" })

   -- Get 3x3 grid around collision point
   local grid = {}
   for dy = -1, 1 do
      grid[dy] = {}
      for dx = -1, 1 do
         local x, y = tx + dx, ty + dy
         grid[dy][dx] = level:inBounds(x, y) and level:getCellPassable(x, y, mask)
      end
   end

   -- Determine approach vector
   local approachX = tx - fromX
   local approachY = ty - fromY
   local approachAngle = math.atan2(approachY, approachX)

   -- Check if we're hitting a clear horizontal or vertical wall surface
   local leftBlocked = not grid[0][-1]
   local rightBlocked = not grid[0][1]
   local upBlocked = not grid[-1][0]
   local downBlocked = not grid[1][0]

   -- Count wall continuity in each direction
   local horizontalWallLength = 0
   local verticalWallLength = 0

   -- Check horizontal wall continuity (walls above and below)
   if upBlocked or downBlocked then
      if not grid[-1][-1] then horizontalWallLength = horizontalWallLength + 1 end -- up-left
      if not grid[-1][1] then horizontalWallLength = horizontalWallLength + 1 end  -- up-right
      if not grid[1][-1] then horizontalWallLength = horizontalWallLength + 1 end  -- down-left
      if not grid[1][1] then horizontalWallLength = horizontalWallLength + 1 end   -- down-right
   end

   -- Check vertical wall continuity (walls left and right)
   if leftBlocked or rightBlocked then
      if not grid[-1][-1] then verticalWallLength = verticalWallLength + 1 end -- up-left
      if not grid[-1][1] then verticalWallLength = verticalWallLength + 1 end  -- up-right
      if not grid[1][-1] then verticalWallLength = verticalWallLength + 1 end  -- down-left
      if not grid[1][1] then verticalWallLength = verticalWallLength + 1 end   -- down-right
   end

   -- Determine wall type based on pattern and approach
   if horizontalWallLength > verticalWallLength then
      return "horizontal"
   elseif verticalWallLength > horizontalWallLength then
      return "vertical"
   else
      -- Equal or unclear - use approach direction
      local absApproachX = math.abs(approachX)
      local absApproachY = math.abs(approachY)

      if absApproachX > absApproachY then
         return "vertical"   -- Horizontal approach hits vertical surface
      else
         return "horizontal" -- Vertical approach hits horizontal surface
      end
   end
end

-- Helper function to reflect angle based on wall type
local function reflectAngle(angle, wallType)
   if wallType == "horizontal" then
      -- Hit horizontal wall - reflect vertically
      return -angle
   else
      -- Hit vertical wall - reflect horizontally
      return math.pi - angle
   end
end

-- Helper function to normalize angle to [0, 2π]
local function normalizeAngle(angle)
   while angle < 0 do angle = angle + 2 * math.pi end
   while angle >= 2 * math.pi do angle = angle - 2 * math.pi end
   return angle
end

---Calcualtes the path of a bouncing object through the world.
---@param level Level
---@param source Vector2 Source position of the bouncing projcetile.
---@param distance number How many tiles to travel until stopping.
---@param angle number Angle, in radians, to travel.
--- @return BounceResult[]
function RULES.bounce(level, source, distance, angle)
   local result = {}
   local currentPos = source:copy()
   local currentAngle = normalizeAngle(angle)
   local distanceTraveled = 0
   local mask = prism.Collision.createBitmaskFromMovetypes({ "fly" })

   -- TODO consider if it's a number of bounces versus distance limit.
   while distanceTraveled < distance do
      -- Get direction vector for current angle
      local direction = prism.Vector2(math.cos(currentAngle), math.sin(currentAngle))

      -- Calculate destination for remaining distance
      local remainingDistance = distance - distanceTraveled
      local destination = currentPos + direction * remainingDistance



      destination.x, destination.y = math.floor(destination.x + 0.5), math.floor(destination.y + 0.5)
      -- Use Bresenham to trace the path
      local path = prism.Bresenham(currentPos.x, currentPos.y, destination.x, destination.y)

      if not path then
         break
      end

      local pathPoints = path:getPath()
      local hitWall = false
      local lastValidPos = currentPos:copy()

      -- Walk along the path until we hit something
      for i, pos in ipairs(pathPoints) do
         if i > 1 then -- skip starting position
            -- Floor the position to get grid coordinates
            -- (I'm not SURE this is necessary but leaving it here for now...)
            local gridPos = prism.Vector2(math.floor(pos.x + 0.5), math.floor(pos.y + 0.5))

            -- Always increment distance traveled for each step
            distanceTraveled = distanceTraveled + 1

            -- if we sense an adjacent explosion-triggering entity
            -- ... explode.
            local explode = false
            for _, dir in ipairs(prism.Vector2.neighborhood8) do
               if #level:query(prism.components.TriggersExplosives):at((dir + gridPos):decompose()):gather() > 0 and distanceTraveled >= GRENADE_MINIMUM_ARM_DISTANCE then
                  explode = true
               end
            end

            -- Check if this tile is passable
            if not level:inBounds(gridPos.x, gridPos.y) or
                not level:getCellPassable(gridPos.x, gridPos.y, mask) then
               -- handle reflection
               local wallType = getWallType(level, gridPos.x, gridPos.y, lastValidPos.x, lastValidPos.y)
               currentAngle = normalizeAngle(reflectAngle(currentAngle, wallType))
               currentPos = lastValidPos
               hitWall = true

               table.insert(result, {
                  pos = lastValidPos:copy(),
                  distance = distanceTraveled,
                  bounce = true,
                  explode = explode
               })
               break
            end

            lastValidPos = prism.Vector2(pos.x, pos.y)

            -- Add every step to the result
            table.insert(result, {
               pos = lastValidPos:copy(),
               distance = distanceTraveled,
               bounce = false,
               explode = explode
            })

            if distanceTraveled >= distance or explode then break end
         end
      end

      if not hitWall then
         -- Traveled full distance without hitting anything
         currentPos = lastValidPos
         table.insert(result, {
            pos = currentPos:copy(),
            distance = distanceTraveled,
            bounce = false,
            explode = true
         })
         break
      end
   end

   return result
end
