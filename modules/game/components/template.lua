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
      for x = -template.range, template.range do
         for y = -template.range, template.range do
            local distance = math.sqrt(x * x + y * y)
            if distance <= template.range then
               table.insert(positions, target + prism.Vector2(x, y))
            end
         end
      end
   elseif template.type == "line" then
      -- Generate line from source towards target
      local direction = (target - source):normalize()
      local maxDistance = math.min(template.range, (target - source):length())

      -- Use Bresenham to generate line points
      local endPoint = source + direction * maxDistance
      local path = prism.Bresenham(source.x, source.y, math.floor(endPoint.x + 0.5), math.floor(endPoint.y + 0.5))

      if path then
         local pathPoints = path:getPath()
         for _, point in ipairs(pathPoints) do
            table.insert(positions, prism.Vector2(point.x, point.y))
         end
      end
   elseif template.type == "wedge" then
      -- Generate wedge from source towards target
      local direction = target - source
      local centerAngle = math.atan2(direction.y, direction.x)
      local halfArc = template.arcLength / 2
      local startAngle = centerAngle - halfArc
      local endAngle = centerAngle + halfArc

      -- Generate positions within the wedge
      for x = -template.range, template.range do
         for y = -template.range, template.range do
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
