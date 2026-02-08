--- @class StunnedModifier : ConditionModifier
--- @overload fun(): StunnedModifier
local StunnedModifier = prism.condition.ConditionModifier:extend "StunnedModifier"

function StunnedModifier:__new()
end

return StunnedModifier
