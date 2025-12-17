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

   prism.logger.info("has inventory")

   local weapon = inventory:query(prism.components.Active):first()

   if not weapon then return false end

   prism.logger.info("has inventory and weapon: ", weapon:getName())


   -- now we have a weapon to use, see if we can use it to shoot a target

   -- see if we can sense the player
   local targetActor = nil
   for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
      ---@cast entity Actor
      if entity:has(prism.components.PlayerController) then
         targetActor = entity
      end
   end

   if not targetActor then
      prism.logger.info("No player target sensed.")
      return false
   end

   local target = targetActor:getPosition()
   local shoot = prism.actions.ItemAbility(actor, weapon, target)

   local s, e = level:canPerform(shoot)

   -- now we also need to check if there is currently a shot scheduled, that will use up more ammo.
   if controller.intent and prism.actions.ItemAbility:is(controller.intent) then
      -- check if the intent is to use the same item as we're using here.
      local sameItem = controller.intent:getItem() == weapon

      if sameItem and not prism.components.Cost.canUseMultiple(actor, weapon, 2) then
         return false
      end
   end

   if s then
      return shoot
   else
      prism.logger.info("Failed to shoot with error: ", e)
      return false
   end
end

return ShootBehavior
