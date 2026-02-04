--- @class AlwaysShoot : BehaviorTree.Node
local AlwaysShoot = prism.BehaviorTree.Node:extend("AlwaysShoot")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller
--- @return boolean|Action
function AlwaysShoot:run(level, actor, controller)
   local inventory = actor:get(prism.components.Inventory)

   if not inventory then return false end

   local weapon = inventory:query(prism.components.Active):first()

   if not weapon then return false end

   -- shoot at self
   local action = prism.actions.ItemAbility(actor, weapon, prism.Vector2(0, 0))

   -- local s, e = level:canPerform(action)
   prism.logger.info("returning shoot action")
   return action
   -- if s then
   --    return action
   -- else
   --    prism.logger.info("Tried to self-shoot, failed: ", e)
   --    return false
   -- end
end

return AlwaysShoot
