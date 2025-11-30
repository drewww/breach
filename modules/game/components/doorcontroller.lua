--- A controller component that opens doors when an actor moves adjacent to it.
--- @class DoorController : Controller
--- @overload fun(): DoorController
--- @type DoorController
local DoorController = prism.components.Controller:extend "DoorController"

--- @class DoorController : Controller
--- @field sensesMover "null"|"nothing"|"something"

DoorController.sensesMover = "null"

function DoorController:act(level, actor)
   -- if there is an adjacent actor, switch from open to closed.
   local adjacentMover = false

   for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
      if entity:has(prism.components.Mover) then
         adjacentMover = true
      elseif entity:has(prism.components.DoorController) and entity ~= actor and not actor:hasRelation(prism.relations.DoorLinkedRelation, entity) then
         -- Found an adjacent door that's not already linked - make one simple relation
         if actor:getRange(entity, "manhattan") == 1 then
            actor:addRelation(prism.relations.DoorLinkedRelation, entity)
            prism.logger.info("Linked doors: ", actor:getName(), " <-> ", entity:getName())
         end
      end
   end

   if adjacentMover then
      self.sensesMover = "something"
   else
      self.sensesMover = "nothing"
   end

   -- Check if any linked doors sense something
   local allNothing = self.sensesMover ~= "something"
   local quorum = true
   local relations = actor:getRelations(prism.relations.DoorLinkedRelation)

   for entity, relation in pairs(relations) do
      --- @type DoorController
      local controller = entity:get(prism.components.DoorController)

      -- if any linked entity is null, no quorum
      if controller.sensesMover == "null" then
         quorum = false
      end

      -- if any linked entity is something, there can't be nothing
      if controller.sensesMover == "something" then
         allNothing = false
      end
   end

   --- @type Action?
   local action = prism.actions.Wait(actor)
   if quorum then
      if allNothing then
         action = prism.actions.ToggleDoor(actor, false) -- close door
      else
         action = prism.actions.ToggleDoor(actor, true)  -- open door
      end

      -- Reset votes on linked doors and propagate action
      for entity, _ in pairs(relations) do
         --- @type DoorController
         local controller = entity:get(prism.components.DoorController)
         controller.sensesMover = "null"

         local spreadAction = nil
         if allNothing then
            spreadAction = prism.actions.ToggleDoor(entity, false)
         else
            spreadAction = prism.actions.ToggleDoor(entity, true)
         end

         level:tryPerform(spreadAction)
      end

      self.sensesMover = "null"
   end

   local canPerform, error = level:canPerform(action)
   if canPerform then
      return action
   end

   return prism.actions.Wait(actor)
end

return DoorController
