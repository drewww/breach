--- @class AnimateOptions
--- @field name string
--- @field duration number
--- @field color Color4

--- @class Animate : Component
--- @field name string
--- @field duration number
--- @field color Color4

local Animate = prism.Component:extend("Animate")
Animate.name = "Animate"

function Animate:__new(options)
   self.name = options.name or "Bullet"
   self.duration = options.duration or 0.2
   self.color = options.color or prism.Color4.PINK
end

return Animate
