--- @class SelectWaypoint : BehaviorTree.Node
local SelectWaypoint = prism.BehaviorTree.Node:extend("SelectWaypoint")

--- @param self SelectWaypoint
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function SelectWaypoint:run(level, actor, controller)
   -- look in blackboard to see if we have a waypoint
   -- if we do, check and see if we're within 1 range of it.
   -- if we are, then pick a new one.
   -- if we're not, do nothing.
   -- if we don't have a waypoint, pick a waypoint.

   if not controller.blackboard.waypoint then
      controller.blackboard.waypoint = self:findWaypoint(level)
      controller.blackboard.path = nil
   else
      local distance = actor:getPosition():distance(controller.blackboard.waypoint)

      -- pick a new waypoint if we're adjacent to our destination
      if distance <= 1 then
         controller.blackboard.waypoint = self:findWaypoint(level)
         controller.blackboard.path = nil
      end
   end

   if not controller.blackboard.path then
      controller.blackboard.path = self:getPathToWaypoint(level, actor, controller.blackboard.waypoint)
   end

   prism.logger.info("exiting waypoint with waypoint set to: ", controller.blackboard.waypoint)
   return false
end

--- @return Vector2|nil
function SelectWaypoint:findWaypoint(level)
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

function SelectWaypoint:getPathToWaypoint(level, actor, destination)
   local mover = actor:get(prism.components.Mover)

   local path = level:findPath(actor:getPosition(), destination, actor, mover.mask, 1, "8way", function(x, y)
      -- removed mine avoidance for now
      -- for _, pos in ipairs(positionsToAvoid) do
      --    if pos.x == x and pos.y == y then
      --       -- TODO this could be health-aware; if you can tank the mine, maybe do it??
      --       return 200
      --    end
      -- end

      -- TODO add wall adjacency avoiding here
      return 1
   end)

   return path
end

return SelectWaypoint
