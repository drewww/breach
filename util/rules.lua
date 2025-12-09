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
--- @field pos Vector2
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

      -- Create push result for this step
      local pushResult = {
         pos = nextPos,
         collision = collision
      }

      table.insert(results, pushResult)

      if collision then
         prism.logger.info("COLLISION:", nextPos)
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
