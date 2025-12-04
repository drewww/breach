--- A relation representing that an actor is followed by another Actor.
--- @class FollowedByRelation : Relation
--- @overload fun(): FollowedByRelation
local FollowedByRelation = prism.Relation:extend "FollowedByRelation"

function FollowedByRelation:generateInverse()
   return prism.relations.FollowsRelation
end

return FollowedByRelation
