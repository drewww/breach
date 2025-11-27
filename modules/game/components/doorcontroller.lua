--- A controller component that opens doors when an actor moves adjacent to it.
--- @class DoorController : Controller
--- @overload fun(): DoorController
--- @type DoorController
local DoorController = prism.components.Controller:extend "DoorController"

function DoorController:act(level, actor)
   -- if there is an adjacent actor, switch from open to closed.
   local adjacentActors = {}

   for _, vec in pairs(prism.neighborhood) do
      local x, y = (actor:getPosition() + vec):decompose()

      level:query(prism.components.Mover):at(x, y):gather(adjacentActors)
   end

   local action = nil
   if #adjacentActors > 0 then
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
