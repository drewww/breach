local DashDestination = prism.Target()
    :isPrototype(prism.Vector2)
    :range(2, "manhattan")

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
   return level:getCellPassableByActor(destination.x, destination.y, self.owner, dasher.mask)
end

--- @param level Level
--- @param destination Vector2
function Dash:perform(level, destination)
   level:moveActor(self.owner, destination)
end

return Dash
