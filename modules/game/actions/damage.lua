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

local function triggerGasJet(level, target)
   local emitter = target:expect(prism.components.GasEmitter)

   if emitter.disabled then
      emitter.disabled = false
      level:yield(prism.messages.AnimationMessage({
         animation = spectrum.animations.Jet(
            target,
            0.25,
            GAS_TYPES["smoke"].index,
            GAS_TYPES["smoke"].bgFading,
            5
         ),
         actor = target,
         blocking = true,
         skippable = false
      }))
   end
end

function Damage:perform(level, target, amount)
   local healthC = target:expect(prism.components.Health)

   healthC.value = healthC.value - amount

   if healthC.value <= 0 then
      local die = prism.actions.Die(target)
      level:tryPerform(die)
   end

   if target:has(prism.components.Name) and target:has(prism.components.GasEmitter) then
      triggerGasJet(level, target)
   end

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
