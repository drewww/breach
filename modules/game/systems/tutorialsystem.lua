--- @class TutorialSystem : System
--- @field step "start"|"blink"|"melee"|"ranged"|"environment"
local TutorialSystem = prism.System:extend("TutorialSystem")

-- We're going to need some list of states. Can we keep these in here? The problem is the PlayState will need to handle transitioning between states. We can fire messages from here back out to ask for it. But how do we know we've completed the transition?
-- Basic question: Where do I preload the messages saying "welcome" and "show me you can move" -- I don't want this in PlayState because it's going to get awfully big. So we're going to need to track the TutorialSystem as a


---@param level Level
function TutorialSystem:init(level)
   self.level = level
   self:step("start")
end

function TutorialSystem:step(step)
   self.step = step

   local player = self.level:query(prism.components.PlayerController):first()
   if not player then return end

   local dialog = player:expect(prism.components.Dialog)

   if step == "start" then
      dialog:push("Welcome, operator.")

      -- do entering-step actions
   elseif step == "melee" then
      -- do entering-step action
   end
end

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
