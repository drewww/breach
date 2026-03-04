--- @class WaypointPlan : BehaviorTree.Node
local WaypointPlan = prism.BehaviorTree.Node:extend("WaypointPlan")

--- @param self WaypointPlan
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function WaypointPlan:run(level, actor, controller)
   -- look in Destination component to see if we have a waypoint
   -- if we do, check and see if we're within 1 range of it.
   -- if we are, then pick a new one.
   -- if we're not, do nothing.
   -- if we don't have a waypoint, pick a waypoint.

   local destination = actor:get(prism.components.Destination)

   if not destination then destination = prism.components.Destination() end

   prism.logger.info("in waypoint, destination: ", destination.pos)

   if not destination.pos then
      level:perform(prism.actions.SetState(actor, "PATROLLING"))

      local waypoint = self:findWaypoint(level)
      prism.logger.info("Setting new waypoint destination: ", waypoint)
      level:perform(prism.actions.SetDestination(actor, waypoint, false))
      return false
   else
      local distance = actor:getPosition():getRange(destination.pos, "chebyshev")

      -- pick a new waypoint if we're adjacent to our destination
      if distance <= 1 then
         prism.logger.info("picking a new waypoint because we're adjacent to the old one")
         level:perform(prism.actions.SetDestination(actor, self:findWaypoint(level), false))
         return false
      end
   end

   -- this is intended to be the "final" fallback behavior
   return false
end

--- @return Vector2|nil
function WaypointPlan:findWaypoint(level)
   -- get waypoints in an AOE.
   -- we have to scan all the cells to find waypoint cells........
   local waypoints = {}
   for x, y in level.map:each() do
      local cell = level:getCell(x, y)
      if cell and cell:has(prism.components.Waypoint) then
         table.insert(waypoints, prism.Vector2(x, y))
      end
   end

   -- pick a random one
   if #waypoints == 0 then
      return nil
   end
   return waypoints[RNG:random(1, #waypoints)]
end

return WaypointPlan
