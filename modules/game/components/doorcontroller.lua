--- A controller component that opens doors when an actor moves adjacent to it.
--- @class DoorController : Controller
--- @overload fun(): DoorController
--- @type DoorController
local DoorController = prism.components.Controller:extend "DoorController"

local function addDoorRelations(actor, doorActor)
   if actor ~= doorActor then
      actor:addRelation(prism.relations.DoorLinkedRelation, doorActor)
      doorActor:addRelation(prism.relations.DoorLinkedRelation, actor)

      -- now get the list of doors THAT door is connected to, and add it here. RECURSE!
      for entity, relation in pairs(doorActor:getRelations(prism.relations.SeesRelation)) do
         if entity:hasRelation(prism.relations.DoorLinkedRelation, doorActor) or doorActor:hasRelation(prism.relations.DoorLinkedRelation) then
            prism.logger.info("Already linked.")
            return
         else
            prism.logger.info("Not linked, linking + recursing.")
            addDoorRelations(entity, doorActor)
         end
      end
   end
end

--- @class DoorController : Controller
--- @field sensesMover "null"|"nothing"|"something"

DoorController.sensesMover = "null"

function DoorController:act(level, actor)
   -- if there is an adjacent actor, switch from open to closed.
   local adjacentMover = false


   for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
      -- prism.logger.info("checking sees relations ", entity:getName(), entity:has(prism.components.Mover),
      --    entity:has(prism.components.DoorController), entity == actor)

      if entity:has(prism.components.Mover) then
         adjacentMover = true
      elseif entity:has(prism.components.DoorController) and entity ~= actor and not actor:hasRelation(prism.relations.DoorLinkedRelation, entity) then
         --- @type Actor
         local doorActor = entity
         if actor:getRange(doorActor, "manhattan") == 1 and not actor:hasRelation(prism.relations.DoorLinkedRelation, doorActor) then
            addDoorRelations(actor, doorActor)
         end
      end
   end


   if adjacentMover then
      -- action = prism.actions.ToggleDoor(actor, prism.actions.ToggleDoor.OPEN) -- open door
      self.sensesMover = "something"
   else
      -- if WE don't sense a mover, check if any our links do
      self.sensesMover = "nothing"
      -- action = prism.actions.ToggleDoor(actor, prism.actions.ToggleDoor.CLOSE) -- close door)
   end

   -- now, check all links and see if they have an answer.
   local allNothing = self.sensesMover ~= "something" -- if THIS door sees something, this should start as false
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

   -- now if quorum (i.e. no doors null) THEN if allNothing? close all
   -- if not allNothing? open all
   prism.logger.info("quorum? ", quorum, " allNothing? ", allNothing)

   --- @type Action?
   local action = prism.actions.Wait(actor)
   if quorum then
      if allNothing then
         action = prism.actions.ToggleDoor(actor, prism.actions.ToggleDoor.CLOSE)
      else
         action = prism.actions.ToggleDoor(actor, prism.actions.ToggleDoor.OPEN)
      end

      -- now if we have quorum, reset the votes on everyone
      for entity, _ in pairs(relations) do
         --- @type DoorController
         local controller = entity:get(prism.components.DoorController)
         controller.sensesMover = "null"
         prism.logger.info("resetting relation to null")

         --- @type Action?
         local spreadAction = nil
         if allNothing then
            spreadAction = prism.actions.ToggleDoor(entity, prism.actions.ToggleDoor.CLOSE)
         else
            spreadAction = prism.actions.ToggleDoor(entity, prism.actions.ToggleDoor.OPEN)
         end

         local performed, err = level:tryPerform(spreadAction)
         prism.logger.info("propagated action: ", performed, err)
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
