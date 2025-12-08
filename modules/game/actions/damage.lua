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

local function triggerGasJet(level, source, target)
   local emitter = target:expect(prism.components.GasEmitter)

   if emitter.disabled then
      -- Calculate direction from source to target
      local sourcePos = source:getPosition()
      local targetPos = target:getPosition()
      local directionVector = targetPos - sourcePos

      -- Use atan2 to get angle, then map to clockwise rotations where 0 is right
      local angle = math.atan2(directionVector.y, directionVector.x)
      -- Convert to degrees and normalize to 0-360
      local degrees = math.deg(angle)
      if degrees < 0 then degrees = degrees + 360 end

      -- Map angle ranges to directions (0=right, 1=down, 2=left, 3=up)
      local direction
      if degrees >= 315 or degrees < 45 then
         direction = 2 -- right
      elseif degrees >= 45 and degrees < 135 then
         direction = 1 -- down
      elseif degrees >= 135 and degrees < 225 then
         direction = 0 -- left
      else             -- 225 to 315
         direction = 3 -- up
      end

      emitter.direction = direction

      emitter.disabled = false
      level:yield(prism.messages.AnimationMessage({
         animation = spectrum.animations.Jet(
            target,
            0.25,
            GAS_TYPES["smoke"].index,
            GAS_TYPES["smoke"].bgFading,
            5,
            direction
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
      triggerGasJet(level, self.owner, target)
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
