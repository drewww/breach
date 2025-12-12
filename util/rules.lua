RULES = {}

DASH_DISTANCE = 2
DASH_NEIGHBORHOOD = prism.Vector2.neighborhood4

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
      local farthestDirection = prism.Vector2(0, 0)

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

      results[dir] = farthestDirection
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

-- Helper function to determine wall type based on neighboring tiles
local function getWallType(level, tx, ty, fromX, fromY)
   -- Safe bounds checking for neighboring tiles
   local leftPassable = level:inBounds(tx - 1, ty) and
       level:getCellPassable(tx - 1, ty, prism.Collision.createBitmaskFromMovetypes({ "fly" })) or false
   local rightPassable = level:inBounds(tx + 1, ty) and
       level:getCellPassable(tx + 1, ty, prism.Collision.createBitmaskFromMovetypes({ "fly" })) or false
   local upPassable = level:inBounds(tx, ty - 1) and
       level:getCellPassable(tx, ty - 1, prism.Collision.createBitmaskFromMovetypes({ "fly" })) or false
   local downPassable = level:inBounds(tx, ty + 1) and
       level:getCellPassable(tx, ty + 1, prism.Collision.createBitmaskFromMovetypes({ "fly" })) or false

   -- If left/right are passable but up/down aren't, it's a horizontal wall
   if (leftPassable or rightPassable) and not (upPassable or downPassable) then
      return "horizontal"
      -- If up/down are passable but left/right aren't, it's a vertical wall
   elseif (upPassable or downPassable) and not (leftPassable or rightPassable) then
      return "vertical"
   else
      -- Corner or complex geometry - use approach direction
      return math.abs(fromX - tx) > math.abs(fromY - ty) and "vertical" or "horizontal"
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

   prism.logger.info("Starting bounce loop with distance:", distance, "currentPos:", currentPos, "angle:", currentAngle)

   while distanceTraveled < distance do
      prism.logger.info("Loop iteration: distanceTraveled=", distanceTraveled, " distance=", distance)

      -- Get direction vector for current angle
      local direction = prism.Vector2(math.cos(currentAngle), math.sin(currentAngle))

      -- Calculate destination for remaining distance
      local remainingDistance = distance - distanceTraveled
      local destination = currentPos + direction * remainingDistance

      prism.logger.info("About to call Bresenham from:", currentPos, "to:", destination)

      destination.x, destination.y = math.floor(destination.x + 0.5), math.floor(destination.y + 0.5)
      -- Use Bresenham to trace the path
      local path = prism.Bresenham(currentPos.x, currentPos.y, destination.x, destination.y)

      prism.logger.info("Bresenham returned:", path, "type:", type(path))

      if not path then
         prism.logger.info("Bresenham returned nil, breaking")
         break
      end

      local pathPoints = path:getPath()
      prism.logger.info("Got path points, count:", #pathPoints)
      local hitWall = false
      local lastValidPos = currentPos:copy()

      -- Walk along the path until we hit something
      for i, pos in ipairs(pathPoints) do
         if i > 1 then -- skip starting position
            -- Floor the position to get grid coordinates
            local gridPos = prism.Vector2(math.floor(pos.x + 0.5), math.floor(pos.y + 0.5))

            -- Always increment distance traveled for each step
            distanceTraveled = distanceTraveled + 1

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
                  bounce = true
               })
               break
            end

            lastValidPos = prism.Vector2(pos.x, pos.y)

            -- Add every step to the result
            table.insert(result, {
               pos = lastValidPos:copy(),
               distance = distanceTraveled,
               bounce = false
            })

            if distanceTraveled >= distance then break end
         end
      end

      if not hitWall then
         -- Traveled full distance without hitting anything
         currentPos = lastValidPos
         table.insert(result, {
            pos = currentPos:copy(),
            distance = distanceTraveled,
            bounce = false
         })
         break
      end
   end

   return result
end
