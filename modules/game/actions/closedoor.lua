---@class CloseDoor : Action
local CloseDoor = prism.Action:extend("CloseDoor")

function CloseDoor:canPerform()
   -- actor needs a doorcontroller?
   -- doesn't need to have collider or opaque
   return not (self.owner:has(prism.components.Opaque)
      or self.owner:has(prism.components.Collider))
end

function CloseDoor:perform(level)
   self.owner:give(prism.components.Opaque())
   self.owner:give(prism.components.Collider())

   local drawable = self.owner:get(prism.components.Drawable)
   if drawable then
      local swap = drawable.background
      drawable.background = drawable.color
      drawable.color = swap
   end
end

return CloseDoor
