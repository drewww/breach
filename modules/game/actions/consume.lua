---@class Consume : Action
local Consume = prism.Action:extend("Consume")

local Item = prism.Target(prism.components.Item):outsideLevel()

Consume.targets = { Item }
Consume.requiredComponents = { prism.components.Inventory, prism.components.Slots }

function Consume:canPerform()
   return true
end

function Consume:perform(level, item)
   local slots = self.owner:expect(prism.components.Slots)
   local inventory = self.owner:expect(prism.components.Inventory)

   slots:removeItem(item)

   local value = item:get(prism.components.Value)
   local stackCount = item:expect(prism.components.Item).stackCount

   local credits = prism.actors.Credits(value and value.credits * stackCount or 1 * stackCount)
   inventory:addItem(credits)

   local totalCredits = inventory:getStack("credits"):expect(prism.components.Item).stackCount

   prism.logger.info("Total credits: ", totalCredits)
end

return Consume
