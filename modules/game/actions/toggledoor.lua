---@class ToggleDoor : Action
local ToggleDoor = prism.Action:extend("ToggleDoor")

local OpenDoorTarget = prism.Target():isType("number")

ToggleDoor.targets = { OpenDoorTarget }

ToggleDoor.OPEN = 1
ToggleDoor.CLOSE = 2

local function isDoorClosed(actor)
   return actor:has(prism.components.Opaque) and actor:has(prism.components.Collider)
end

function ToggleDoor:canPerform(level, open)
   local isClosed = isDoorClosed(self.owner)

   open = open == ToggleDoor.OPEN

   if open and isClosed then
      return true
   elseif not open and not isClosed then
      return true
   else
      return false
   end

   return false
end

function ToggleDoor:perform(level, open)
   open = open == ToggleDoor.OPEN

   if open then
      -- Open the door
      self.owner:remove(prism.components.Opaque)
      self.owner:remove(prism.components.Collider)
   else
      -- Close the door
      self.owner:give(prism.components.Opaque())
      self.owner:give(prism.components.Collider())
   end

   -- Swap colors to reflect state change
   local drawable = self.owner:get(prism.components.Drawable)
   if drawable then
      local swap = drawable.background
      drawable.background = drawable.color
      drawable.color = swap
   end
end

return ToggleDoor
