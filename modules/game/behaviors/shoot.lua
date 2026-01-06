--- @class ShootBehavior : BehaviorTree.Node
local ShootBehavior = prism.BehaviorTree.Node:extend("ShootBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller, IIntentful
--- @return boolean|Action
function ShootBehavior:run(level, actor, controller)
   prism.logger.info("running shoot behavior")
   -- pick a location to shoot. for now, just pick a random one.
   local inventory = actor:get(prism.components.Inventory)

   if not inventory then return false end

   local weapon = inventory:query(prism.components.Active):first()

   if not weapon then return false end

   local range = weapon:expect(prism.components.Range)
   local template = weapon:expect(prism.components.Template)

   -- now we have a weapon to use, see if we can use it to shoot a target

   -- see if we can sense the player
   local targetActor = nil
   -- for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
   --    ---@cast entity Actor
   --    if entity:has(prism.components.PlayerController) then
   --       targetActor = entity
   --    end
   -- end

   -- try a version that uses range directly instead of SeesRelation
   local player = level:query(prism.components.PlayerController):first()

   if player then
      local rangeToPlayer = player:getPosition():getRange(actor:getPosition(), "chebyshev")

      -- in the burst case, we want to add in the effect range.
      prism.logger.info("rangeToPlayer: ", rangeToPlayer, range.min, range.max, template.range)

      -- TODO we're going to need a custom range check for burst bots
      if rangeToPlayer < range.min or rangeToPlayer > range.max then
         return false
      else
         targetActor = player
      end
   end


   if not targetActor then
      prism.logger.info("No player target sensed (in range mode).")
      return false
   end

   -- Shoot at the actual target position for validation purposes.
   -- For line templates, the visual effect will automatically extend to template.range,
   -- shooting through and beyond the target. This allows canPerform to validate the
   -- true target (enemy position) while the template extends the full weapon range.
   -- Example: Bot at (4,9) shoots at player at (8,6) - validates player visibility,
   -- but laser extends 8 cells total in that direction, going past the player.
   local direction = targetActor:getPosition() - actor:getPosition()
   local shoot = prism.actions.ItemAbility(actor, weapon, direction)

   local s, e = level:canPerform(shoot)

   if s then
      return shoot
   else
      prism.logger.info("Failed to shoot with error: ", e)
      return false
   end
end

return ShootBehavior
