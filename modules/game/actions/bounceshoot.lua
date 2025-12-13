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

   -- so actually the only thing that has to happen is to trigger an explosion at the last point.
   -- everything else is visual, the animation. (one could have the bounces do something to the world, I suppose. but for now, no.)

   -- so we have two steps:
   -- 1. trigger animation that animates through all the points in the list smoothly.
   -- 2. explode on the last spot.

   local steps = {}
   for _, b in ipairs(bounces) do
      table.insert(steps, b.pos)
   end

   level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.Bounce(steps, 0.05 * #steps),
      blocking = true,
      skipptable = true
   }))

   local s, e = level:tryPerform(prism.actions.Explode(self.owner, steps[#steps - 1], 3))
   prism.logger.info("explode: ", s, e, steps[#steps].pos)
end

return BounceShoot
