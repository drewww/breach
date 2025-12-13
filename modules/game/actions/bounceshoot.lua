local AngleTarget = prism.Target():isType("number")
local DistanceTarget = prism.Target():isType("number")

---@class BounceShoot : Action
local BounceShoot = prism.Action:extend("BounceShoot")

BounceShoot.targets = { AngleTarget, DistanceTarget }

function BounceShoot:canPerform(angle, distance)
   return (distance > 0)
end

function BounceShoot:perform(level, angle, distance)
   local bounces = RULES.bounce(level, self.owner:getPosition(), distance, angle)
end

return BounceShoot
