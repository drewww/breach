--- @class Facing : Component
--- @field dir Vector2
local Facing = prism.Component:extend("Facing")
Facing.name = "Facing"

function Facing:__new(indexes)
   self.dir = prism.Vector2(1, 0)
   self.indexes = indexes
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
