local AngleTarget = prism.Target():isType("number")
local DistanceTarget = prism.Target():isType("number")

-- Normalize angle to [0, 2pi] range
local function normalizeAngle(angle)
   while angle < 0 do angle = angle + 2 * math.pi end
   while angle >= 2 * math.pi do angle = angle - 2 * math.pi end
   return angle
end

---@class BounceShoot : Action
local BounceShoot = prism.Action:extend("BounceShoot")

BounceShoot.targets = { AngleTarget, DistanceTarget }

function BounceShoot:canPerform(level, angle, distance)
   return (distance > 0)
end

function BounceShoot:perform(level, angle, distance)
   -- Normalize the angle to handle negative values from atan2
   angle = normalizeAngle(angle)
   local bounces = RULES.bounce(level, self.owner:getPosition(), distance, angle)

   -- so actually the only thing that has to happen is to trigger an explosion at the last point.
   -- everything else is visual, the animation. (one could have the bounces do something to the world, I suppose. but for now, no.)

   -- so we have two steps:
   -- 1. trigger animation that animates through all the points in the list smoothly.
   -- 2. explode on the last spot.

   local steps = {}
   for _, b in ipairs(bounces) do
      table.insert(steps, b.pos)
   end

   if #steps == 0 then
      return
   end

   level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.Bounce(steps, 0.05 * #steps),
      blocking = true,
      skipptable = true
   }))

   local s, e = level:tryPerform(prism.actions.Explode(self.owner, steps[#steps], 3))
   prism.logger.info("explode: ", s, e, steps[#steps].pos)
end

return BounceShoot
