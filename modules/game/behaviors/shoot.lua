--- @class ShootBehavior : BehaviorTree.Node
local ShootBehavior = prism.BehaviorTree.Node:extend("ShootBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller, IIntentful
--- @return boolean|Action
function ShootBehavior:run(level, actor, controller)
   prism.logger.info("running shoot behavior")

   if controller.blackboard and not controller.blackboard.priorActionPerformed and prism.actions.ItemAbility:is(controller.blackboard.priorAction) then
      prism.logger.info("Item use failed last turn, not trying again.")
      return false
   end

   local inventory = actor:get(prism.components.Inventory)

   if not inventory then return false end

   local weapon = inventory:query(prism.components.Active):first()

   if not weapon then return false end

   local range = weapon:expect(prism.components.Range)
   local template = weapon:expect(prism.components.Template)

   -- now we have a weapon to use, see if we can use it to shoot a target

   -- see if we can sense the player
   local targetActor = nil

   local player = level:query(prism.components.PlayerController):first()

   if player then
      local rangeToPlayer = player:getPosition():getRange(actor:getPosition(), "chebyshev")

      -- TODO URGENT We need to make this respect vision. This is the laser shooting behind walls problem.
      local sensesPlayer = player:hasRelation(
         prism.relations.SensedByRelation, actor)

      if (rangeToPlayer < range.min or rangeToPlayer > range.max) or not sensesPlayer then
         prism.logger.info("range: ", rangeToPlayer, " [", range.min, "-", range.max, "] sensesPlayer: ", sensesPlayer)
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


   local scatter = weapon:get(prism.components.Scatter)
   local target = targetActor:getPosition()

   if scatter then
      -- pick a random angle and random magnitude
      local angle = math.random() * math.pi * 2
      local magnitude = math.random() * (scatter.max_range - scatter.min_range) + scatter.min_range

      prism.logger.info("scattering: ", angle, magnitude, target)

      target = target + prism.Vector2(magnitude * math.cos(angle), math.sin(magnitude * angle))

      target = target:round()

      prism.logger.info("new target: ", target)
   end

   local direction = target - actor:getPosition()
   local shoot = prism.actions.ItemAbility(actor, weapon, direction)

   -- check canTarget AND canFire.
   local costLegal, cooldownLegal = shoot:canFire(level)
   local rangeLegal, seesLegal, pathsLegal, targetContainsPlayerIfNecessary = shoot:canTarget(level)

   if costLegal and cooldownLegal and rangeLegal and seesLegal and pathsLegal and targetContainsPlayerIfNecessary then
      return shoot
   else
      prism.logger.info(string.format("cost %s, cooldown %s, range %s, sees %s, paths %s", tostring(costLegal),
         tostring(cooldownLegal), tostring(rangeLegal), tostring(seesLegal), tostring(pathsLegal)))
      return false
   end
end

return ShootBehavior
