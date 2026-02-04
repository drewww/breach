--- @class ReloadBehavior : BehaviorTree.Node
local ReloadBehavior = prism.BehaviorTree.Node:extend("ReloadBehavior")

--- @param self BehaviorTree.Node
--- @param level Level
--- @param actor Actor
--- @param controller Controller, IIntenful
--- @return boolean|Action
function ReloadBehavior:run(level, actor, controller)
   local inventory = actor:expect(prism.components.Inventory)

   local item = inventory:query(prism.components.Active):first()

   if not item then
      return false
   end

   local clip = item:get(prism.components.Clip)
   local cost = item:get(prism.components.Cost)

   if not clip or not cost then
      -- active item is not reloadable
      return false
   end


   local reload = prism.actions.Reload(actor, item, true)

   local s, e = level:canPerform(reload)
   prism.logger.info("canPerform reload: ", s, e)

   -- if we intend to fire and it will use up our clip,
   -- prepare to reload next.

   if s and clip.ammo < cost.ammo then
      return reload
   else
      return false
   end
end

return ReloadBehavior
