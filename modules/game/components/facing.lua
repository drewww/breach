--- @class FacingOptions
--- @field indexes number[]
--- @field dir Vector2


--- @class Facing : Component
--- @field dir Vector2
local Facing = prism.Component:extend("Facing")
Facing.name = "Facing"

---@param options FacingOptions
function Facing:__new(options)
   if not options then

   end

   if options and options.dir then
      self.dir = options.dir:normalize()
   else
      self.dir = prism.Vector2(1, 0)
   end

   if options and options.indexes then
      self.indexes = options.indexes
   else
      self.indexes = {}
   end
end

function Facing:set(dir)
   self.dir = dir:normalize():copy()
end

function Facing:setAngle(angle)
   self.dir = prism.Vector2(math.cos(angle), math.sin(angle))
end

---@return number The angle in radians of facing.
function Facing:getAngle()
   return math.atan2(self.dir.y, self.dir.x)
end

function Facing:getIndex()
   local angle = math.atan2(self.dir.y, self.dir.x)
   local degrees = math.deg(angle)

   if degrees < 0 then
      degrees = degrees + 360
   end

   local result = 0
   if degrees >= 315 or degrees < 45 then
      result = 1
   elseif degrees >= 45 and degrees < 135 then
      result = 2
   elseif degrees >= 135 and degrees < 225 then
      result = 3
   else
      result = 4
   end

   prism.logger.info("angle: ", degrees, result)


   return result
end

--- @param d Drawable
function Facing:updateDrawable(d)
   if self.indexes and #self.indexes > 0 then
      local index = self:getIndex()
      if index <= #self.indexes then
         d.index = self.indexes[index]
      end
   end
end

return Facing
