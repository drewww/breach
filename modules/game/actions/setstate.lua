local State = prism.Target():isType("string")


---@class SetState : Action
local SetState = prism.Action:extend("SetState")

SetState.targets = { State }

function SetState:canPerform(level, state)
   return self.owner:has(prism.components.BehaviorState)
end

function SetState:perform(level, state)
   local behaviorState = self.owner:expect(prism.components.BehaviorState)

   behaviorState.state = state

   local player = level:query(prism.components.PlayerController):first()
   if (self.owner:hasRelation(prism.relations.SensedByRelation, player)) then
      level:yield(prism.messages.OverlayAnimationMessage({
         animation = spectrum.animations.TextReveal(self.owner, state, 0.5, 1.5, prism.Color4.BLACK,
            prism.Color4.YELLOW, { worldPos = true, actorOffset = prism.Vector2(1, -1) }
         ),
         actor = self.owner,
         blocking = false,
         skippable = false,
      }))
   end
end

return SetState
