---@class Damage : Action
local Damage = prism.Action:extend("Damage")

local DamageAmount = prism.Target():isType("number")
local DamageTarget = prism.Target(prism.components.Health)
local DamageColor = prism.Target():isPrototype(prism.Color4)
-- TODO damage types -- could be fire, poison, electrical(?)
-- TODO push damage? pierching damge?

Damage.targets = { DamageTarget, DamageAmount, DamageColor }

-- will need to have some sort of attacker requirement here
Damage.requiredComponents = {}

function Damage:canPerform(level, target, amount, color)
   if amount <= 0 then
      return false, "Damage amount must be greater than 0, not " .. amount
   end

   return true
end

function Damage:perform(level, target, amount, color)
   local healthC = target:expect(prism.components.Health)

   healthC.value = healthC.value - amount

   if healthC.value <= 0 then
      -- TODO implement Die action.
      prism.logger.info("Target should die, health is ", healthC.value)
   else
      prism.logger.info("Target now at ", healthC.value, " hp.")
   end

   if target:has(prism.components.DamagedColors) and color and target:has(prism.components.Drawable) then
      --- @type Drawable
      local drawable = target:expect(prism.components.Drawable)
      drawable.color = drawable.color:lerp(color, 0.05)
   end
end

return Damage
