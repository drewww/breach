--- @class TutorialSystem : System
--- @field step "start"|"blink"|"melee"|"ranged"|"environment"
local TutorialSystem = prism.System:extend("TutorialSystem")

-- We're going to need some list of states. Can we keep these in here? The problem is the PlayState will need to handle transitioning between states. We can fire messages from here back out to ask for it. But how do we know we've completed the transition?
-- Basic question: Where do I preload the messages saying "welcome" and "show me you can move" -- I don't want this in PlayState because it's going to get awfully big. So we're going to need to track the TutorialSystem as a


---@param level Level
function TutorialSystem:init(level)
   prism.logger.info("INIT")
   self.level = level
   self:step("start")
end

function TutorialSystem:step(step)
   self.step = step

   local player = self.level:query(prism.components.PlayerController):first()
   if not player then return end

   local dialog = player:expect(prism.components.Dialog)

   if step == "start" then
      dialog:push("Welcome, operator. We expect this mandatory training to take five minutes.")
      dialog:push("You should find the controls to be familiar. W, A, S, and D will move you orthogonally.")

      -- do entering-step actions
      local x, y = math.random(2, 5), math.random(2, 5)
      local cell = self.level:getCell(x, y)
      cell:give(prism.components.Trigger())
      self:pulseCell(x, y)
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

function TutorialSystem:pulseCell(x, y)
   prism.logger.info("triggering pulse at ", x, y)

   self.level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.Pulse(x, y, prism.Color4.BLACK, prism.Color4.GREEN, 0.5),
      blocking = false,
      skippable = false
   }))
end

return TutorialSystem
