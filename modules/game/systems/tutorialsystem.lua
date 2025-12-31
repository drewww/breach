--- @class TutorialSystem : System
local TutorialSystem = prism.System:extend("TutorialSystem")

function TutorialSystem:onMove(level, actor, from, to)
   prism.logger.info("actor moved: ", actor, from, to)
end

function TutorialSystem:onActorRemoved(level, actor)
   prism.logger.info("actor removed: ", actor)
end

function TutorialSystem:onComponentAdded(level, actor, component)
   prism.logger.info("component added: ", actor, component)
end

function TutorialSystem:onComponentRemoved(level, actor, component)
   prism.logger.info("component removed: ", actor, component)
end

return TutorialSystem
