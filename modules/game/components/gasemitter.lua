--- A controller component that stops to wait for input to receive its action.
--- @class GasEmitter : Component
--- @field gas GasTypeName
--- @field direction number angle in radians
--- @field template Vector2[] An array of points in which the actor is 0,0 and 1,0 is direction=0. It will be rotated by direction.
--- @field volume number Amount of gas to release by turn.

--- @type GasEmitter
local GasEmitter = prism.Component:extend "GasEmitter"

--- @class GasEmitter
--- @param gas GasTypeName
--- @param direction number
--- @param template Vector2[]
--- @param volume number
function GasEmitter:__new(gas, direction, template, volume)
   self.gas = gas
   self.direction = direction
   self.template = template
   self.volume = volume
end

return GasEmitter
