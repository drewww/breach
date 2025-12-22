local Angle = prism.Target():isType("number")

---@class Rotate : Action
local Rotate = prism.Action:extend("Rotate")

Rotate.targets = { Angle }

function Rotate:canPerform(level, angle)
   return self.owner:has(prism.components.Facing)
end

function Rotate:perform(level, angle)
   local facing = self.owner:expect(prism.components.Facing)

   -- get the facing angle, then add the incremental angle, then bake it back into
   -- a directional vector.
   local newAngle = angle + facing:getAngle()
   facing:setAngle(newAngle)
end

return Rotate
