--- @class EffectOptions
--- @field health? integer Health damage (i.e. basic damage) (default: 0)
--- @field healthPierce? integer Armor penetration (default: 0)
--- @field push? integer Push strength (default: 0)
--- @field pushPierce? integer Push pierce (default: 0)

--- Represents damaging effects an ability can have. You can have multiple overlapping damage-type effects.
--- @class Effect : Component
--- @field health integer health damage (i.e. basic damage)
--- @field healthPierce integer armor penetration
--- @field push integer push strength
--- @field pushPierce integer
--- TODO More fields can add here like: elemental damage types.
local Effect = prism.Component:extend("Effect")
Effect.name = "Effect"

--- @param options? EffectOptions
function Effect:__new(options)
   options = options or {}

   self.health = options.health or 0
   self.healthPierce = options.healthPierce or 0
   self.push = options.push or 0
   self.pushPierce = options.pushPierce or 0
end

return Effect
