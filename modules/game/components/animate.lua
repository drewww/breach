--- @class AnimateOptions
--- @field name string
--- @field duration number
--- @field color Color4
--- @field index number|string

--- @class Animate : Component
--- @field name string
--- @field duration number
--- @field color Color4
--- @field index number|string

local Animate = prism.Component:extend("Animate")
Animate.name = "Animate"

function Animate:__new(options)
   self.name = options.name or "Projectile"
   self.duration = options.duration or 0.2
   self.color = options.color or prism.Color4.PINK
   self.index = options.index or "!"
end

return Animate
