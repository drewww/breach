--- A controller component that opens doors when an actor moves adjacent to it.
--- @class DoorController : Controller
--- @overload fun(): DoorController
--- @type DoorController
local DoorController = prism.components.Controller:extend "DoorController"

function DoorController:act(level, actor)
   -- if there is an adjacent actor, switch from open to closed.
   local adjacentMover = false
   for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
      if entity:has(prism.components.Mover) then
         adjacentMover = true
      end
   end

   local action = nil

   if adjacentMover then
      action = prism.actions.ToggleDoor(actor, prism.actions.ToggleDoor.OPEN)  -- open door
   else
      action = prism.actions.ToggleDoor(actor, prism.actions.ToggleDoor.CLOSE) -- close door)
   end

   local canPerform, error = level:canPerform(action)
   if canPerform then
      return action
   else
      return prism.actions.Wait(actor)
   end
end

return DoorController
