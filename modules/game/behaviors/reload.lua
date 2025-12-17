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

   local reload = prism.actions.Reload(actor, item)

   local s, e = level:canPerform(reload)

   -- if we intend to fire and it will use up our clip,
   -- prepare to reload next.
   local reloadAt = 0

   if clip and s and clip.ammo == reloadAt then
      return reload
   else
      return false
   end
end

return ReloadBehavior
