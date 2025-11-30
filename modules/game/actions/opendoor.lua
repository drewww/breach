---@class OpenDoor : Action
local OpenDoor = prism.Action:extend("OpenDoor")

function OpenDoor:canPerform()
   -- actor needs a doorcontroller?
   -- doesn't need to have collider or opaque
   return self.owner:has(prism.components.Opaque)
       and self.owner:has(prism.components.Collider)
end

function OpenDoor:perform(level)
   self.owner:remove(prism.components.Opaque)
   self.owner:remove(prism.components.Collider)

   local drawable = self.owner:get(prism.components.Drawable)
   if drawable then
      local swap = drawable.background
      drawable.background = drawable.color
      drawable.color = swap
   end
end

return OpenDoor
