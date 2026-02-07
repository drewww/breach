--- @class ITemplate
--- @field type "point"|"line"|"wedge"|"circle"|"arc"
--- @field range number
--- @field arcLength number
--- @field excludeOrigin boolean
--- @field mask table Movement types that block this projectile
--- @field mustSeePlayerToFire boolean If true, ability cannot be used if the player is not in the template when using.
--- @field requiredComponents Component[] a list of components that must be present on at least one actor in the template area to fire
--- @field multishot boolean? If true, fire one projectile to each point in the template


--- Template utility functions for working with ITemplate instances.
--- Contains static methods for template calculations.
TEMPLATE = {}

---Returns the nearest position to the position argument that satisfies the range constraints.
---@param source Actor
---@param target Vector2
---@param ranges Range
---@return Vector2
function TEMPLATE.adjustPositionForRange(source, target, ranges)
   local range = source:getPosition():getRange(target, "euclidean")

   local result = target:copy()
   -- if in ranges, no change.
   if ranges.min <= range and ranges.max >= range then
      return target
   end

   if range == 0 then
      return prism.Vector2(1, 0) * ranges.min + source:getPosition()
   end

   -- otherwise, scale the vector down to the unit vector, and scale it to the min or mix
   -- magnitude depending on which constraint we're violating.
   local vec = (target - source:getPosition()):normalize()

   if range < ranges.min then
      result = vec * ranges.min
   elseif range > ranges.max then
      result = vec * ranges.max
   end

   return result:round() + source:getPosition()
end

--- Calculates the actual impact point for a projectile, accounting for obstacles.
--- Traces a Bresenham line from source toward intended target, stopping early if it hits:
--- 1. The intended target position
--- 2. An actor with TriggersExplosives component (barrel, etc.)
--- 3. An impassable cell (based on template's passability mask)
---
--- @param level Level The game level
--- @param shooter Actor The actor shooting (with position)
--- @param weapon Actor The weapon item (with Template or Trigger, Range components)
--- @param intendedTarget Vector2 The desired target position (world coordinates)
--- @return Vector2 The actual impact point where projectile stops
function TEMPLATE.calculateActualTarget(level, shooter, weapon, intendedTarget)
   local template = weapon:get(prism.components.Template) or weapon:get(prism.components.Trigger)
   local range = weapon:expect(prism.components.Range)

   if not template then
      return intendedTarget
   end

   local sourcePos = shooter:getPosition()
   if not sourcePos then
      return intendedTarget
   end

   local direction = intendedTarget - sourcePos
   local normalizedDirection = direction:normalize()
   local endpoint = sourcePos + normalizedDirection * range.max

   -- Create passability mask from template (e.g., "walk" for ground projectiles, "fly" for flying)
   local mask = prism.Collision.createBitmaskFromMovetypes(template.mask or { "walk" })

   -- Trace the line to find where the shot actually stops
   local actualTarget = intendedTarget

   local startX = math.floor(sourcePos.x + 0.5)
   local startY = math.floor(sourcePos.y + 0.5)
   local endX = math.floor(endpoint.x + 0.5)
   local endY = math.floor(endpoint.y + 0.5)

   prism.bresenham(startX, startY, endX, endY, function(x, y)
      -- Skip the starting position
      if x == startX and y == startY then
         return true
      end

      local currentPos = prism.Vector2(x, y)

      -- Check if we hit the intended target position
      if currentPos.x == intendedTarget.x and currentPos.y == intendedTarget.y then
         actualTarget = currentPos
         return false -- Stop tracing
      end

      -- Check if there's an actor with TriggersExplosives at this position
      local actorsHere = level:query(prism.components.TriggersExplosives):at(x, y):gather()
      if #actorsHere > 0 then
         actualTarget = currentPos
         return false -- Stop tracing - hit an explosive trigger
      end

      -- Check if the cell is passable based on the template's passability mask
      -- e.g., "walk" mask hits walls and actors, "fly" mask only hits walls
      if not level:inBounds(x, y) or not level:getCellPassable(x, y, mask, 1) then
         actualTarget = currentPos
         return false
      end

      -- This cell is clear, continue tracing
      actualTarget = currentPos
      return true
   end)

   return actualTarget
end

--- Generates the actual Vector2 positions (in world coordinates) for this template
--- @param template ITemplate
--- @param source Vector2 Source position
--- @param target Vector2 Target position (the actual aim point, e.g., enemy position)
--- @return Vector2[] Array of world positions
---
--- IMPORTANT: For line templates, the target defines the DIRECTION to aim, but the line
--- always extends to template.range cells from the source. This means the line can shoot
--- through and beyond the target position. This design allows ability validation to check
--- the true target (e.g., can the bot see the enemy?) while the visual effect extends the
--- full weapon range (e.g., laser continues past the enemy for 8 cells total).
function TEMPLATE.generate(template, source, target)
   local positions = {}

   if template.type == "point" then
      table.insert(positions, target:copy())
   elseif template.type == "circle" then
      -- Generate circle centered at target
      for x = -math.ceil(template.range), math.ceil(template.range) do
         for y = -math.ceil(template.range), math.ceil(template.range) do
            local distance = math.sqrt(x * x + y * y)
            if distance <= template.range then
               local pos = prism.Vector2(x, y) + target
               table.insert(positions, pos:round())
            end
         end
      end
   elseif template.type == "line" then
      -- Generate line from source towards target direction for specified range
      -- IMPORTANT: The 'target' parameter defines the direction to aim, but the line
      -- always extends to template.range cells from the source, potentially going
      -- through and beyond the target. This allows validation to check the true target
      -- position while the visual effect extends the full weapon range.
      local direction = target - source
      local directionLength = direction:length()

      if directionLength > 0 then
         -- Calculate the actual endpoint at template.range distance (not target distance)
         local normalizedDirection = direction:normalize()
         local endPoint = source + normalizedDirection * template.range

         -- Use Bresenham to generate line points
         local startX = math.floor(source.x + 0.5)
         local startY = math.floor(source.y + 0.5)
         local endX = math.floor(endPoint.x + 0.5)
         local endY = math.floor(endPoint.y + 0.5)

         local path = prism.bresenham(startX, startY, endX, endY)

         if path then
            local pathPoints = path:getPath()
            for i, point in ipairs(pathPoints) do
               if i > 1 then -- Skip the first point (origin)
                  table.insert(positions, prism.Vector2(point.x, point.y))
               end
            end
         end
      else
         -- If source == target, just add the source position
         table.insert(positions, source:copy())
      end
   elseif template.type == "wedge" then
      -- Generate wedge from source towards target
      local direction = target - source
      local centerAngle = math.atan2(direction.y, direction.x)
      local halfArc = template.arcLength / 2
      local startAngle = centerAngle - halfArc
      local endAngle = centerAngle + halfArc

      -- Generate positions within the wedge (support floating point ranges)
      local maxRange = math.ceil(template.range)
      for x = -maxRange, maxRange do
         for y = -maxRange, maxRange do
            local offset = prism.Vector2(x, y)
            local worldPos = source + offset
            local pointDistance = offset:length()

            if pointDistance <= template.range and pointDistance > 0 then
               local pointAngle = math.atan2(y, x)

               -- Normalize angles for comparison
               local function normalizeAngle(angle)
                  while angle < -math.pi do angle = angle + 2 * math.pi end
                  while angle > math.pi do angle = angle - 2 * math.pi end
                  return angle
               end

               local normPointAngle = normalizeAngle(pointAngle)
               local normStartAngle = normalizeAngle(startAngle)
               local normEndAngle = normalizeAngle(endAngle)

               -- Check if point is within the arc
               local inArc = false
               if normStartAngle <= normEndAngle then
                  inArc = normPointAngle >= normStartAngle and normPointAngle <= normEndAngle
               else
                  -- Arc wraps around -π/π boundary
                  inArc = normPointAngle >= normStartAngle or normPointAngle <= normEndAngle
               end

               if inArc then
                  table.insert(positions, worldPos)
               end
            end
         end
      end
   elseif template.type == "arc" then
      -- Generate N points along an arc at fixed range (e.g., shotgun pellets)
      -- Each point is a destination for one projectile
      local direction = target - source
      local centerAngle = math.atan2(direction.y, direction.x)
      local halfArc = (template.arcLength or (math.pi / 4)) / 2
      local startAngle = centerAngle - halfArc
      local endAngle = centerAngle + halfArc

      local pointCount = template.arcLength / (math.pi / 32)

      for i = 1, pointCount do
         local angle
         if pointCount == 1 then
            angle = centerAngle
         else
            -- Distribute evenly across the arc (including edges)
            local t = (i - 1) / (pointCount - 1)
            angle = startAngle + t * (endAngle - startAngle)
         end

         -- Calculate endpoint at template.range distance
         local endX = source.x + math.cos(angle) * template.range
         local endY = source.y + math.sin(angle) * template.range
         local endpoint = prism.Vector2(endX, endY):round()

         table.insert(positions, endpoint)
      end
   end

   -- Deduplicate positions using a set
   local seen = {}
   local finalPositions = {}
   for _, pos in ipairs(positions) do
      local rounded = pos:round()
      local key = rounded.x .. "," .. rounded.y

      if not seen[key] then
         seen[key] = true
         -- Apply excludeOrigin filter
         if not template.excludeOrigin or (rounded.x ~= source.x or rounded.y ~= source.y) then
            table.insert(finalPositions, rounded)
         end
      end
   end

   return finalPositions
end
