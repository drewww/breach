local DashDestination = prism.Target()
    :isPrototype(prism.Vector2)
    :range(2, "manhattan") -- Sync this up with DASH_DISDTANCE in util/rules

---@class Dash : Action
---@field name string
---@field targets Target[]
---@field previousPosition Vector2
local Dash = prism.Action:extend("Dash")
Dash.name = "dash"
Dash.targets = { DashDestination }

Dash.requiredComponents = {
   prism.components.Controller,
   prism.components.Dasher
}

--- @param level Level
--- @param destination Vector2
function Dash:canPerform(level, destination)
   local dasher = self.owner:expect(prism.components.Dasher)
   local cellPassable = level:getCellPassableByActor(destination.x, destination.y, self.owner, dasher.mask)

   local energyAvailable = false
   if self.owner:has(prism.components.Energy) then
      local energy = self.owner:expect(prism.components.Energy)

      if energy.current >= 2 then
         energyAvailable = true
      end
   end

   return energyAvailable and cellPassable
end

--- @param level Level
--- @param destination Vector2
function Dash:perform(level, destination)
   level:yield(prism.messages.AnimationMessage {
      animation = spectrum.animations.Move(level, self.owner, destination, 0.1),
      actor = self.owner,
      blocking = true,
      skippable = false,
      override = true
   })

   local energy = self.owner:expect(prism.components.Energy)

   energy.current = math.max(energy.current - 2, 0)

   level:moveActor(self.owner, destination)
end

return Dash
