--- @class EffectOptions
--- @field health? integer Health damage (i.e. basic damage) (default: 0)
--- @field healthPierce? integer Armor penetration (default: 0)
--- @field push? integer Push strength (default: 0)
--- @field pushPierce? integer Push pierce (default: 0)
--- @field pushFromCenter? boolean If true, calculate the push relative to the template origin.
--- @field spawnActor? string The name of the actor to spawn.
--- @field actorOptions? table A table of options for the actor. Will be unpacked.
--- @field crit? number Probability of critical hit (0-1) (default: 0)
--- @field condition? Condition A condition to apply to affected entities.

--- Represents damaging effects an ability can have. You can have multiple overlapping damage-type effects.
--- @class Effect : Component
--- @field health integer health damage (i.e. basic damage)
--- @field healthPierce integer armor penetration
--- @field push integer push strength
--- @field pushPierce integer
--- @field pushFromCenter boolean If true, calculate the push relative to the template origin.
--- @field spawnActor string The name of the actor to spawn.
--- @field actorOptions table A table of options for the actor. Will be unpacked.
--- @field crit_chance number Probability of critical hit (0-1)
--- @field condition Condition A condition to apply to affected entities.

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
   self.pushFromCenter = options.pushFromCenter or false

   self.spawnActor = options.spawnActor or nil
   self.actorOptions = options.actorOptions or {}

   self.crit = options.crit or 0

   self.condition = options.condition or nil
end

---Returns the push vector based on self.pushFromCenter
--- @param target Actor
--- @param user Actor
--- @param pos Vector2
--- @param Vector2
function Effect:getPushVector(target, user, pos)
   local vector = target:getPosition() - user:getPosition()

   if self.pushFromCenter then
      vector = target:getPosition() - pos
   end

   return vector
end

return Effect
