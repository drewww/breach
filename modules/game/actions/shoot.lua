local ShootTarget = prism.Target():isActor()
local DamageTarget = prism.Target():isType("number")
local PushAmount = prism.Target():isType("number")

---@class Shoot : Action
local Shoot = prism.Action:extend("Shoot")
function Shoot:canPerform()
   return true
end

Shoot.targets = { ShootTarget, DamageTarget, PushAmount }

function Shoot:perform(level, target, damage, pushAmount)
   level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.Bullet(0.2, self.owner, target),
      blocking = true,
      skippable = true
   }))

   level:tryPerform(prism.actions.Damage(self.owner, target, damage))

   if pushAmount > 0 then
      local vector = target:getPosition() - self.owner:getPosition()

      vector = vector:normalize()
      level:tryPerform(prism.actions.Push(self.owner, target, vector, pushAmount, false))
   end
end

return Shoot
