--- A relation representing that an actor follows another actor.
--- @class FollowsRelation : Relation
--- @overload fun(): FollowsRelation
local FollowsRelation = prism.Relation:extend "FollowsRelation"

function FollowsRelation:generateInverse()
   return prism.relations.FollowsRelation
end

return FollowsRelation
