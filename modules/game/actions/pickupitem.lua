---@class PickupItem : Action
local PickupItem = prism.Action:extend("PickupItem")

local Item = prism.Target(prism.components.Item):outsideLevel()

PickupItem.targets = { Item }

PickupItem.requiredComponents = { prism.components.Slots }

function PickupItem:canPerform()
   return true
end

function PickupItem:perform(level, item)
   local slots = self.owner:expect(prism.components.Slots)

   local slot = slots:insert(item)

   if slot then
      item:remove(prism.components.Position)
      level:removeActor(item)
   end
end

return PickupItem
