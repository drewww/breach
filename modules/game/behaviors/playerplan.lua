--- @class PlayerPlan : BehaviorTree.Node
local PlayerPlan = prism.BehaviorTree.Node:extend("PlayerPlan")

--- @param self PlayerPlan
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function PlayerPlan:run(level, actor, controller)
   -- Always set destination to the player's current location
   local player = level:query(prism.components.PlayerController):first()

   if not player then
      -- No player found, can't plan
      return false
   end

   local playerPos = player:getPosition()
   if not playerPos then
      -- Player has no position
      return false
   end

   local destination = actor:get(prism.components.Destination)

   if not destination then
      destination = prism.components.Destination()
   end

   -- Always update destination to player's current position
   level:perform(prism.actions.SetState(actor, "HUNTING"))
   level:perform(prism.actions.SetDestination(actor, playerPos, false))

   return false
end

return PlayerPlan
