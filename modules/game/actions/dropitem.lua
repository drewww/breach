---@class DropItem : Action
local DropItem = prism.Action:extend("DropItem")

local Item = prism.Target(prism.components.Item):outsideLevel()

DropItem.targets = { Item }
DropItem.requiredComponents = { prism.components.Slots }

function DropItem:canPerform(level, item)
   -- as long as target validation passes, we can drop.
   -- I guess we could check to see if there's any adjacent spaces that are walk passable??
   return #self:getEligibleDropPositions(level) > 0
end

function DropItem:perform(level, item)
   -- remove it from the action owner
   local slots = self.owner:expect(prism.components.Slots)

   slots:removeItem(item)
   local eligible = self:getEligibleDropPositions(level)

   -- drop it in a random adjacent spot
   item:give(prism.components.Position())
   level:addActor(item, eligible[RNG:random(1, #eligible)]:decompose())
end

--- @return Vector2[]
function DropItem:getEligibleDropPositions(level)
   -- now look at all adjacent spaces
   local eligible = {}
   for i = -1, 1 do
      for j = -1, 1 do
         -- make sure the space is passable
         local offset = self.owner:getPosition() + prism.Vector2(i, j)
         local actors = level:query():at(offset:decompose()):gather()

         -- checks to see if the owner oculd move here, sort of a hack but okay
         local passable = level:getCellPassable(offset.x, offset.y, self.owner:expect(prism.components.Mover).mask)
         local hasActors = #actors ~= 0

         if passable and not hasActors then
            table.insert(eligible, offset)
         end
      end
   end

   return eligible
end

return DropItem
