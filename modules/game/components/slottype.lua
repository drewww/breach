--- @class SlotType : Component
--- @field type string The type of slot (e.g., "Weapon", "Melee", "Utility")
local SlotType = prism.Component:extend("SlotType")
SlotType.name = "SlotType"

--- Constructor for SlotType component.
--- @param slotType string The name of the slot type
function SlotType:__new(slotType)
   assert(type(slotType) == "string", "SlotType must be initialized with a string")
   self.type = slotType
end

return SlotType
