--- @class HuntPlan : BehaviorTree.Node
local HuntPlan = prism.BehaviorTree.Node:extend("HuntPlan")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function HuntPlan:run(level, actor, controller)
   -- update the historical tracking of known player location.
   -- if it's been more than 20 turns since we've seen the player, delete our memory of the location.
   local destination = actor:get(prism.components.Destination)

   -- this is the logic that SHOULD work
   for entity, relation in pairs(actor:getRelations(prism.relations.SensesRelation)) do
      if entity:has(prism.components.Player) then
         local state = actor:get(prism.components.BehaviorState)

         if destination and state and state.state ~= "HUNTING" then
            level:perform(prism.actions.SetState(actor, "HUNTING"))
         end

         local playerDestination = entity:getPosition()

         prism.logger.info("Found player in HUNT: ", playerDestination)
         level:perform(prism.actions.SetDestination(actor, playerDestination, true))
         -- don't let other destinations run, return false
         return false
      end
   end

   -- can we really combine generic destinations with the player
   -- hunting destination? the last seen? it's basically the same
   -- idea ...a place we're going.
   -- oh, this is going to clear ANY destination that takes a while to get to.
   if destination and destination.pos and destination.hunt then
      destination.age = destination.age + 1
      prism.logger.info("player destination age: ", destination.age)
      if destination.age > 10 then
         -- let something else decide on the destination
         level:perform(prism.actions.ClearDestination(actor))

         -- let another planner pick the destination now
         return true
      end
   end



   prism.logger.info("No player found, not setting or clearing a destination.")
   return true
end

return HuntPlan
