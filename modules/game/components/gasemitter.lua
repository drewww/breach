--- A controller component that stops to wait for input to receive its action.
--- @class GasEmitter : Component
--- @field gas GasTypeName
--- @field direction number angle in radians
--- @field template Vector2[] An array of points in which the actor is 0,0 and 1,0 is direction=0. It will be rotated by direction.
--- @field volume number Amount of gas to release by turn.
--- @field duration integer number of turns to persist for, 0 or <0 is infinite
--- @field period integer release every N turns, i.e. period of 2 is every other turn.

--- @class GasEmitterOptions
--- @field gas GasTypeName
--- @field direction number angle in radians
--- @field template Vector2[] An array of points in which the actor is 0,0 and 1,0 is direction=0. It will be rotated by direction.
--- @field volume number Amount of gas to release by turn.
--- @field duration integer number of turns to persist for, 0 or <0 is infinite
--- @field period integer release every N turns, i.e. period of 2 is every other turn.

--- @type GasEmitter
local GasEmitter = prism.Component:extend "GasEmitter"

--- @class GasEmitter
--- @param options GasEmitterOptions
function GasEmitter:__new(options)
   self.gas = options.gas or "smoke"
   self.direction = options.direction or 0
   self.template = options.template or { prism.Vector2(1, 0) }
   self.volume = options.volume or 10
   self.duration = options.duration or 0
   self.period = options.period or 1
end

return GasEmitter
