--- @class TemplateOptions
--- @field type "point"|"line"|"wedge"|"circle"
--- @field range? number For circle: radius. For wedge: maximum distance. For line: maximum length.
--- @field arcLength? number For wedge: total arc length in radians
--- @field excludeOrigin? boolean Whether to include the source position (default: true)
--- @field mask? table Movement types that block this projectile (e.g., {"walk"}, {"fly"})
--- @field mustSeePlayerToFire boolean If true, ability cannot be used if the player is not in the template when using.
--- @field requiredComponents Component[] a list of components that must be present on at least one actor in the template area to fire

--- Represents the shape parameters of an ability effect.
--- Templates store generation parameters, not actual positions.
--- Implements ITemplate interface.
--- @class Template : Component, ITemplate
--- @field type "point"|"line"|"wedge"|"circle"
--- @field range number
--- @field arcLength number
--- @field excludeOrigin boolean
--- @field mask table Movement types that block this projectile
--- @field mustSeePlayerToFire boolean If true, ability cannot be used if the player is not in the template when using.
--- @field requiredComponents Component[] a list of components that must be present on at least one actor in the template area to fire


local Template = prism.Component:extend("Template")
Template.name = "Template"

--- @param options TemplateOptions
function Template:__new(options)
   options = options or {}

   self.type = options.type or "point"
   self.range = options.range or 1
   self.arcLength = options.arcLength or math.pi / 4 -- 45 degrees default
   self.excludeOrigin = options.excludeOrigin or false
   self.mask = options.mask or { "walk" }            -- Default: blocked by ground obstacles
   self.mustSeePlayerToFire = options.mustSeePlayerToFire or false

   self.requiredComponents = options.requiredComponents or {}
end

return Template
