local Destination = prism.Target():isPrototype(prism.Vector2)

-- TODO fix when boolean targets are working
local SuppressAnimation = prism.Target():isType("number"):optional()

---@class SetDestination : Action
local SetDestination = prism.Action:extend("SetDestination")

SetDestination.targets = { Destination, SuppressAnimation }

function SetDestination:canPerform()
   return true
end

function SetDestination:perform(level, destination, supressAnimation)
   if self.owner:has(prism.components.Destination) then
      self.owner:expect(prism.components.Destination).pos = destination
   else
      self.owner:give(prism.components.Destination(destination))
   end

   if not supressAnimation or supressAnimation == "0" then
      local oX, oY = (self.owner:getPosition() * 2):decompose()
      oX, oY = oX + 1, oY - 1

      level:yield(prism.messages.OverlayAnimationMessage({
         animation = spectrum.animations.TextReveal(self.owner, "Patrolling...", 0.5, 1.5, prism.Color4.BLACK,
            prism.Color4.YELLOW, { worldPos = true, actorOffset = prism.Vector2(1, -1) }
         ),
         actor = self.owner,
         blocking = true,
         skippable = false,
      }))
   end

   return true
end

return SetDestination
