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
      action = prism.actions.OpenDoor(actor)
   else
      action = prism.actions.CloseDoor(actor)
   end

   if level:canPerform(action) then
      return action
   else
      return prism.actions.Wait(actor)
   end
end

return DoorController
