--- @class TutorialLoadMapMessage : Message
--- @field map string The filename to load a prefab for.
--- @overload fun(prefab : string): TutorialLoadMapMessage

local TutorialLoadMapMessage = prism.Message:extend "TutorialLoadMapMessage"

function TutorialLoadMapMessage:__new(map)
   self.map = map
end

return TutorialLoadMapMessage
