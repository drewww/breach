--- A relation representing that a door linked to another door.
--- @class DoorLinkedRelation : Relation
--- @overload fun(): DoorLinkedRelation
local DoorLinkedRelation = prism.Relation:extend "DoorLinkedRelation"

function DoorLinkedRelation:generateSymmetric()
   return prism.relations.DoorLinkedRelation
end

return DoorLinkedRelation
