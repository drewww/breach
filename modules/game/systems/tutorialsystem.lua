--- @class TutorialSystem : System
--- @field step "start"|"blink"|"melee"|"ranged"|"environment"|"move"
local TutorialSystem = prism.System:extend("TutorialSystem")

-- We're going to need some list of states. Can we keep these in here? The problem is the PlayState will need to handle transitioning between states. We can fire messages from here back out to ask for it. But how do we know we've completed the transition?
-- Basic question: Where do I preload the messages saying "welcome" and "show me you can move" -- I don't want this in PlayState because it's going to get awfully big. So we're going to need to track the TutorialSystem as a



---@param state LevelState
function TutorialSystem:init(level, state)
   prism.logger.info("INIT")
   self.level = level
   self.state = state
   self.startDestinationsVisited = 0

   self.player = self.level:query(prism.components.PlayerController):first()

   assert(self.player, "No player detected.")

   self.dialog = self.player:expect(prism.components.Dialog)

   self:setStep("start")
end

function TutorialSystem:setStep(step)
   self.step = step

   prism.logger.info("SET STEP: ", step)
end

function TutorialSystem:onMove(level, actor, from, to)

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

--- Allows the tutorial system to deny using certain moves based on the step.
---@return boolean
function TutorialSystem:canMove()
   -- TODO Figure out how to do this! I think it needs to ask for a given control if it should be processed. And this is just a big table of controls and true/false

   self.validControls = {
      start = { "dismiss" },
      move = { "move" }
   }
   if self.step == "start" then
      return false
   elseif self.step == "move" then
      return true
   elseif self.step == "post-move" then
      return false
   end

   return true
end

-- AHHH this doesn't work because dismiss is not a decision. So we'd need something fully custom that says -- when a dismiss UI call happens, call into tutorial system.

function TutorialSystem:onDismiss(level, actor)

end

return TutorialSystem
