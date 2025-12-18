--- @class AnimateOptions
--- @field name string
--- @field duration number
--- @field color Color4
--- @field index number|string
--- @field explode boolean
--- @field radius number
--- @field explodeColor Color4

--- @class Animate : Component
--- @field name string
--- @field duration number
--- @field color Color4
--- @field index number|string
--- @field explode boolean
--- @field radius number
--- @field explodeColor Color4


local Animate = prism.Component:extend("Animate")
Animate.name = "Animate"

function Animate:__new(options)
   self.name = options.name or "Projectile"
   self.duration = options.duration or 0.2
   self.color = options.color or prism.Color4.PINK
   self.index = options.index or "!"

   self.explode = options.explode or false
   self.radius = options.radius or 2
   self.explodeColor = options.radius or prism.Color4.PINK
end

return Animate
