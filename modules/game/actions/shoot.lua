local ShootTarget = prism.Target():isActor()
local DamageTarget = prism.Target():isType("number")

---@class Shoot : Action
local Shoot = prism.Action:extend("Shoot")
function Shoot:canPerform()
   return true
end

Shoot.targets = { ShootTarget, DamageTarget }

function Shoot:perform(level, target, damage)
   level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.Bullet(0.2, self.owner, target),
      blocking = true,
      skippable = true
   }))

   level:tryPerform(prism.actions.Damage(self.owner, target, 2))
end

return Shoot
