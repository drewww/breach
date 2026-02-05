--- @class MoveToPlayer : BehaviorTree.Node
local MoveToPlayer = prism.BehaviorTree.Node:extend("MoveToPlayer")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function MoveToPlayer:run(level, actor, controller)
   local player = level:query(prism.components.PlayerController):first()
   assert(player)

   local mover = actor:expect(prism.components.Mover)

   local positionsToAvoid = {}
   for npc in level:query(prism.components.Intentful):iter() do
      local c = npc:expect(prism.components.BehaviorController)

      if c.intent and prism.actions.ItemAbility:is(c.intent) then
         for _, pos in ipairs(c.intent:getTriggerCells()) do
            table.insert(positionsToAvoid, pos)
         end
      end
   end

   local path = level:findPath(actor:getPosition(), player:getPosition(), actor, mover.mask, 1, "8way", function(x, y)
      -- iterate through actors that are intentful and see if any have shoot intents that impact
      for _, pos in ipairs(positionsToAvoid) do
         if pos.x == x and pos.y == y then
            -- TODO this could be health-aware; if you can tank the mine, maybe do it??
            return 200
         end
      end

      return 1
   end)

   -- prism.logger.info("path: ", path, " from ", actor:getPosition(), " to: ", player:getPosition())

   if not path then
      return false
   end

   local nextStep = path:pop()

   local direction = (nextStep - actor:getPosition())

   direction = prism.Vector2(
      direction.x == 0 and 0 or (direction.x > 0 and 1 or -1),
      direction.y == 0 and 0 or (direction.y > 0 and 1 or -1)
   )

   local action = prism.actions.Move(actor, direction, false)
   local s, e = level:canPerform(action)

   if s then
      return action
   else
      return false
   end
end

return MoveToPlayer
