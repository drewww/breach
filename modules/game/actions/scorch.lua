---@class Scorch : Action
local Scorch = prism.Action:extend("Scorch")

local ScorchTarget = prism.Target(prism.components.Drawable)
local ScorchColor = prism.Target():isPrototype(prism.Color4)
local ScorchIntensity = prism.Target():isType("number")

Scorch.targets = { ScorchTarget, ScorchColor, ScorchIntensity }

function Scorch:canPerform(level, target, color, intensity)
   if intensity <= 0 or intensity > 1.0 then
      return false, "Intensity must be (0, 1.0], not " .. tostring(intensity)
   end

   return true
end

function Scorch:perform(level, target, color, intensity)
   if target:has(prism.components.Scorchable) then
      local drawable = target:expect(prism.components.Drawable)
      drawable.color = drawable.color:lerp(color, intensity)
   end
end

return Scorch
