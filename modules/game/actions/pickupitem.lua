---@class PickupItem : Action
local PickupItem = prism.Action:extend("PickupItem")

local Item = prism.Target(prism.components.Item):outsideLevel()

PickupItem.targets = { Item }

PickupItem.requiredComponents = { prism.components.Slots, prism.components.Inventory }

function PickupItem:canPerform()
   return true
end

function PickupItem:perform(level, item)
   local slots = self.owner:expect(prism.components.Slots)
   local inventory = self.owner:expect(prism.components.Inventory)

   local ammo = string.find(item:getName(), "Ammo")

   prism.logger.info("ammo: ", ammo)

   if (item:expect(prism.components.Item).stackable == "credits") or ammo then
      inventory:addItem(item)
      level:removeActor(item)

      prism.logger.info("adding: ", item:expect(prism.components.Item).stackCount)

      return
   end

   local slot = slots:insert(item)

   if slot then
      item:remove(prism.components.Position)
      level:removeActor(item)
   end
end

return PickupItem
