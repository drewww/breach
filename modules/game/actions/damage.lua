---@class Damage : Action
local Damage = prism.Action:extend("Damage")

local DamageAmount = prism.Target():isType("number")
local DamageTarget = prism.Target(prism.components.Health)
-- TODO damage types -- could be fire, poison, electrical(?)
-- TODO push damage? pierching damge?

Damage.targets = { DamageTarget, DamageAmount }

-- will need to have some sort of attacker requirement here
Damage.requiredComponents = {}

function Damage:canPerform(level, target, amount)
   if amount <= 0 then
      return false, "Damage amount must be greater than 0, not " .. amount
   end

   return true
end

function Damage:perform(level, target, amount)
   local healthC = target:expect(prism.components.Health)

   healthC.value = healthC.value - amount

   if healthC.value <= 0 then
      local die = prism.actions.Die(target)
      level:tryPerform(die)
   end
   prism.logger.info("asking for damage animation")
   level:yield(prism.messages.OverlayAnimationMessage({
      animation = spectrum.animations.TextMove(
         target,
         "-" .. tostring(amount),
         prism.Vector2.UP * 2,
         0.5, prism.Color4.WHITE, prism.Color4.RED, { worldPos = true, actorOffset = prism.Vector2(-2, -2) }
      ),
      actor = target,
      blocking = false,
      skippable = false
   }))
end

return Damage
