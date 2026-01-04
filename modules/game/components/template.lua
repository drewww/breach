--- @class TemplateOptions
--- @field type "point"|"line"|"wedge"|"circle"
--- @field range? number For circle: radius. For wedge: maximum distance. For line: maximum length.
--- @field arcLength? number For wedge: total arc length in radians
--- @field includeOrigin? boolean Whether to include the source position (default: true)

--- Represents the shape parameters of an ability effect.
--- Templates store generation parameters, not actual positions.
--- @class Template : Component
--- @field type "point"|"line"|"wedge"|"circle"
--- @field range number
--- @field arcLength number
--- @field includeOrigin boolean
local Template = prism.Component:extend("Template")
Template.name = "Template"

--- @param options TemplateOptions
function Template:__new(options)
   options = options or {}

   self.type = options.type or "point"
   self.range = options.range or 1
   self.arcLength = options.arcLength or math.pi / 4 -- 45 degrees default
end

---Returns the nearest position to the position argument that satisfies the range constraints.
---@param source Actor
---@param target Vector2
---@param ranges Range
---@return Vector2
function Template.adjustPositionForRange(source, target, ranges)
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

--- Generates the actual Vector2 positions (in world coordinates) for this template
--- @param template Template
--- @param source Vector2 Source position
--- @param target Vector2 Target position
--- @return Vector2[] Array of world positions
function Template.generate(template, source, target)
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
      local direction = target - source
      local directionLength = direction:length()

      if directionLength > 0 then
         -- Calculate the actual endpoint at the specified range distance
         local normalizedDirection = direction:normalize()
         local endPoint = source + normalizedDirection * template.range

         -- Use Bresenham to generate line points
         local startX = math.floor(source.x + 0.5)
         local startY = math.floor(source.y + 0.5)
         local endX = math.floor(endPoint.x + 0.5)
         local endY = math.floor(endPoint.y + 0.5)

         local path = prism.Bresenham(startX, startY, endX, endY)

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
   end

   return positions
end

return Template
