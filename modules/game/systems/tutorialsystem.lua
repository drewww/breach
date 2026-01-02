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

   if step == "start" then
      self.dialog:push("Welcome, operator. We expect this mandatory training to take five minutes.")
      self.dialog:push("You should find the controls to be familiar. W, A, S, and D will move you orthogonally.")
      self.dialog:push("Visit the GREEN spaces to advance. Link enabled.")

      -- we need some way to know when these are dismissed.
   elseif step == "move" then
      -- do entering-step actions
      self:setRandomTrigger()

      -- do entering-step action
   elseif step == "blink" then
      self.state:handleMessage(prism.messages.TutorialLoadMapMessage("blink"))
   end
end

function TutorialSystem:onMove(level, actor, from, to)
   local cellMovedInto = self.level:getCell(to:decompose())

   if self.step == "move" then
      if cellMovedInto:has(prism.components.Trigger) then
         self.startDestinationsVisited = self.startDestinationsVisited + 1

         self:unhighlightCell(to:decompose())
         if self.startDestinationsVisited > 3 then
            prism.logger.info("TRANSITION TO NEXT MODE")
            self.dialog:clear()
            self.dialog:push("Satisfactory. Let's move on.")
            self:setStep("post-move")
         end
         self:setRandomTrigger()
      end
   end
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

function TutorialSystem:highlightCell(x, y)
   local drawable = self.level:getCell(x, y):expect(prism.components.Drawable)
   self.highlightBG = drawable.background:copy()

   drawable.background = prism.Color4.GREEN

   -- self.level:yield(prism.messages.AnimationMessage({
   --    animation = spectrum.animations.Pulse(x, y, prism.Color4.BLACK, prism.Color4.GREEN, 0.5),
   --    blocking = false,
   --    skippable = false
   -- }))
end

function TutorialSystem:unhighlightCell(x, y)
   local cell = self.level:getCell(x, y)
   local drawable = cell:expect(prism.components.Drawable)

   if self.highlightBG then
      drawable.background = self.highlightBG
   else
      drawable.background = prism.Color4.BLACK
   end

   cell:remove(prism.components.Trigger)
end

function TutorialSystem:setNewTrigger(x, y)
   local cell = self.level:getCell(x, y)
   cell:give(prism.components.Trigger())
   self:highlightCell(x, y)
end

function TutorialSystem:setRandomTrigger()
   -- this became intensely un-fun. just hard code it.
   local pos = prism.Vector2(-1, -1)
   if self.startDestinationsVisited == 0 then
      pos = prism.Vector2(2, 2)
   elseif self.startDestinationsVisited == 1 then
      pos = prism.Vector2(6, 6)
   elseif self.startDestinationsVisited == 2 then
      pos = prism.Vector2(2, 6)
   elseif self.startDestinationsVisited == 3 then
      pos = prism.Vector2(4, 4)
   else
      pos = prism.Vector2(-1, -1)
   end

   if self.level:inBounds(pos:decompose()) then
      self:setNewTrigger(pos:decompose())
   end
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
   if self.step == "start" then
      if self.dialog:size() == 0 then
         self:setStep("move")
      end
   elseif self.step == "post-move" then
      if self.dialog:size() == 0 then
         self:setStep("blink")
      end
   end
end

return TutorialSystem
