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


   local oX, oY = (self.owner:getPosition() * 1):decompose()
   level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.TextReveal(oX, oY, "Patrolling...", 0.5, 1.5, prism.Color4.BLACK,
         prism.Color4.YELLOW
      ),
      blocking = false,
      skippable = false
   }))

   return true
end

return SetDestination
