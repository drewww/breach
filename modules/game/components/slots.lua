--- @class SlotDefinition
--- @field type string The slot type name required for this slot (e.g., "Melee", "Weapon", "Utility")
--- @field item Actor|nil The item currently in this slot

--- @class SlotsOptions
--- @field slots SlotDefinition[] Array of slot definitions

--- Manages a fixed number of equipment slots with type constraints.
---
--- Example usage:
--- ```lua
--- -- Create slots
--- local slots = prism.components.Slots({
---    { type = "Melee" },
---    { type = "Weapon" },
---    { type = "Utility" },
--- })
---
--- -- Iterate over all slots
--- for slotNum, item, slotType in slots:iter() do
---    if item then
---       print("Slot", slotNum, "contains", item:expect(prism.components.Name).name)
---    else
---       print("Slot", slotNum, "is empty, accepts", slotType.name)
---    end
--- end
--- ```
---
--- @class Slots : Component
--- @field slots SlotDefinition[] An ordered array of slots, indexed 1 to N in declaration order
local Slots = prism.Component:extend("Slots")
Slots.name = "Slots"

--- Constructor for Slots component.
--- Slots are stored in the exact order provided and maintain that order throughout.
--- @param slots SlotDefinition[] Ordered array of slot definitions, each with a 'type' field containing a slot type string
function Slots:__new(slots)
   assert(type(slots) == "table" and #slots > 0, "Slots must be initialized with a non-empty ordered array")

   self.slots = {}

   -- Preserve the exact order provided
   for i, slotDef in ipairs(slots) do
      assert(slotDef.type, "Each slot definition must have a 'type' field")
      assert(type(slotDef.type) == "string", "Each slot 'type' must be a string")
      self.slots[i] = {
         type = slotDef.type,
         item = nil
      }
   end

   self.active = -1
end

--- Checks if a slot is available (empty).
--- @param slot integer The slot number to check
--- @return boolean available True if the slot is empty
function Slots:available(slot)
   assert(self.slots[slot], "Invalid slot number: " .. tostring(slot))
   return self.slots[slot].item == nil
end

--- Removes and returns the item from a slot.
--- @param slot integer The slot number to remove from
--- @return Actor|nil item The item that was in the slot, or nil if empty
function Slots:remove(slot)
   assert(self.slots[slot], "Invalid slot number: " .. tostring(slot))

   local item = self.slots[slot].item
   self.slots[slot].item = nil

   -- deselect if we removed the active item
   -- later, make this select something automatically
   if self.active == slot then
      self.slot = -1
   end

   return item
end

--- Gets the slot number that contains the given item.
--- @param item Actor The item to find
--- @return integer|nil slot The slot number containing the item, or nil if not found
function Slots:getSlot(item)
   for i, slotDef in ipairs(self.slots) do
      if slotDef.item == item then
         return i
      end
   end
   return nil
end

--- Removes the given item from its slot, if it's in a slot.
--- @param item Actor The item to remove
--- @return Actor|nil item The item that was removed, or nil if it wasn't in any slot
function Slots:removeItem(item)
   local slot = self:getSlot(item)

   prism.logger.info("slot to remove from: ", slot)
   if slot then
      return self:remove(slot)
   end
   return nil
end

--- Inserts an item into a slot if it's compatible and available.
--- @param slot integer The slot number to insert into
--- @param item Actor The item to insert
--- @return boolean success True if the item was inserted successfully
function Slots:insertAt(slot, item)
   assert(self.slots[slot], "Invalid slot number: " .. tostring(slot))

   -- Check if slot is available
   if not self:available(slot) then
      return false
   end

   -- Check if item has the required slot type
   local slotType = item:get(prism.components.SlotType)
   if not slotType or slotType.type ~= self.slots[slot].type then
      return false
   end

   self.slots[slot].item = item

   prism.logger.info("inserted item ", item, "in slot ", slot)

   if self.active == -1 then
      self.active = slot
   end

   return true
end

--- Gets the item in a slot without removing it.
--- @param slot integer The slot number to get from
--- @return Actor|nil item The item in the slot, or nil if empty
function Slots:get(slot)
   assert(self.slots[slot], "Invalid slot number: " .. tostring(slot))
   return self.slots[slot].item
end

--- Finds the first available slot that is compatible with the given item.
--- @param item Actor The item to find a slot for
--- @return integer|nil slot The slot number, or nil if no compatible slot found
function Slots:insert(item)
   local itemSlotType = item:get(prism.components.SlotType)
   if not itemSlotType then
      return nil
   end

   -- do a pass through, looking for a stackable slot
   for i, slotDef in ipairs(self.slots) do
      local slotItem = self:get(i)
      if slotItem then
         local slotItemItem = slotItem:get(prism.components.Item)
         if slotItemItem and itemSlotType.type == slotDef.type and slotItemItem.stackable == item:expect(prism.components.Item).stackable and slotItemItem.stackable then
            slotItemItem.stackCount = slotItemItem.stackCount + item:expect(prism.components.Item).stackCount

            return i
         end
      end
   end

   for i, slotDef in ipairs(self.slots) do
      if itemSlotType.type == slotDef.type and self:available(i) then
         if self.active == -1 then
            self.active = i
         end

         self.slots[i].item = item

         return i
      end
   end

   return nil
end

--- Gets all slot numbers that are compatible with the given slot type name.
--- @param slotTypeName string The slot type name to check (e.g., "Weapon", "Melee", "Utility")
--- @return integer[] slots Array of slot numbers
function Slots:getSlotsForType(slotTypeName)
   local slots = {}
   for i, slotDef in ipairs(self.slots) do
      if slotDef.type == slotTypeName then
         table.insert(slots, i)
      end
   end
   return slots
end

---@param slot integer which slot to activate
--- @return integer which slot is currently active
function Slots:activate(slot)
   if self.slots[slot].item then
      self.active = slot
      return slot
   else
      return self.active
   end
end

--- Returns an iterator that yields information about each slot.
--- @return fun(): (integer|nil, Actor|nil, string|nil) The iterator function
function Slots:iter()
   local i = 0
   local slots = self.slots
   local n = #slots

   return function()
      i = i + 1
      if i <= n then
         return i, slots[i].item, slots[i].type
      end
      return nil
   end
end

---@return Actor?
function Slots:activeItem()
   if self.active == -1 then
      return nil
   end
   return self:get(self.active)
end

return Slots
