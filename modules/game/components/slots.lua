--- @class SlotDefinition
--- @field type Component The component type required for this slot (e.g., Melee, Weapon, Utility)
--- @field item Actor|nil The item currently in this slot

--- @class SlotsOptions
--- @field slots SlotDefinition[] Array of slot definitions

--- Manages a fixed number of equipment slots with type constraints.
--- @class Slots : Component
--- @field slots table<integer, SlotDefinition> The slots indexed by slot number
--- @field active integer

local Slots = prism.Component:extend("Slots")
Slots.name = "Slots"

--- Constructor for Slots component
--- @param slots table Array of slot definitions, each with a 'type' field
function Slots:__new(slots)
   self.slots = {}

   for i, slotDef in ipairs(slots) do
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

   -- Check if item has the required component type
   if not item:has(self.slots[slot].type) then
      return false
   end

   self.slots[slot].item = item

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
   for i, slotDef in ipairs(self.slots) do
      if item:has(slotDef.type) and self:available(i) then
         if self.active == -1 then
            self.active = i
         end

         return i
      end
   end

   return nil
end

--- Gets all slot numbers that are compatible with the given item type.
--- @param componentType Component The component type to check
--- @return integer[] slots Array of slot numbers
function Slots:getSlotsForType(componentType)
   local slots = {}
   for i, slotDef in ipairs(self.slots) do
      if slotDef.type == componentType then
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

return Slots
