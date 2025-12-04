local Destination = prism.Target():isPrototype(prism.Vector2)

---@class SetDestination : Action
local SetDestination = prism.Action:extend("SetDestination")

SetDestination.targets = { Destination }

function SetDestination:canPerform()
   return true
end

function SetDestination:perform(level, destination)
   if self.owner:has(prism.components.Destination) then
      self.owner:expect(prism.components.Destination).pos = destination
   else
      self.owner:give(prism.components.Destination(destination))
   end

   return true
end

return SetDestination
