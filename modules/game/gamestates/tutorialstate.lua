local controls = require "controls"

--- @class TutorialState : PlayState
--- @overload fun(display: Display, overlayDisplay: Display, step: string): TutorialState
local TutorialState = spectrum.gamestates.PlayState:extend "TutorialState"

-- TODO some data structure that holds a list of valid steps.

--- @param display Display
--- @param overlayDisplay Display
function TutorialState:__new(display, overlayDisplay, step)
   prism.logger.info("CONSTRUCT TUTORIAL STATE")

   local map = step or "start"
   local builder = prism.LevelBuilder.fromLz4("modules/game/world/prefab/tutorial/" .. map .. ".lvl")
   
   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 3, 3)

   self.super.__new(self, display, overlayDisplay, builder)

   self.dialog = player:expect(prism.components.Dialog)

   self.startDestinationsVisited = 0
   
   self.moveEnabled = false
   
   self:setStep(step or "start")

end


function TutorialState:updateDecision(dt, owner, decision)
   -- is it a problem if we update controls twice?
   controls:update()
   
   -- this will block other actors too, I think? but doesn't super matter
   if controls.dismiss.pressed and not (controls.move.pressed or controls.use.pressed or controls.dash_mode.down) then
         self.super.updateDecision(self, dt, owner, decision)
         
         -- CONSIDER DISMISS UPDAETS
         prism.logger.info("DISMISS (dialog=",  self.dialog:size(), ")")
         if self.step == "start" and self.dialog:size() == 1 then
            self:setStep("move")
         elseif self.step == "post-move" and self.dialog:size() == 0 then
            self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "blink"))
         end
   elseif self.moveEnabled then
      self.super.updateDecision(self, dt, owner, decision)
   end
   
   -- add on-move here?
   if prism.actions.Move:is(decision.action) then
      local to = decision.action:getDestination()
      local cellMovedInto = self.level:getCell(to:decompose())

   if self.step == "move" or self.step == "blink" then
      if cellMovedInto:has(prism.components.Trigger) then
         self.startDestinationsVisited = self.startDestinationsVisited + 1

         self:unhighlightCell(to:decompose())

         if self.startDestinationsVisited > 2 and self.step == "blink" then
            self.dialog:clear()
            self.dialog:push("Well done. Prepare for weapons training.")
            self:setStep("post-blink")         
         elseif self.startDestinationsVisited > 3 and self.step == "move" then
            self.dialog:clear()
            self.dialog:push("Satisfactory. Let's move on.")
            self:setStep("post-move")
         end
         
         if self.step == "move" then 
            self:setRandomTrigger()
         elseif self.step == "blink" then
            self:setNewTrigger(4, 4)
         end
      end
   end
   end
end

function TutorialState:setStep(step)
   -- TODO validate against step map
   self.step = step
   
   prism.logger.info("STEP enter: ", step)
   
   
   if step == "start" then
      self.dialog:push("Welcome, operator. We expect this mandatory training to take five minutes.")
      self.dialog:push("You should find the controls to be familiar. W, A, S, and D will move you orthogonally.")
      self.dialog:push("Visit the GREEN spaces to advance. Link enabled.")


      -- we need some way to know when these are dismissed.
   elseif step == "move" then
      -- do entering-step actions
            self.moveEnabled = true

      self:setRandomTrigger()

      -- do entering-step action
   elseif step == "blink" then
      prism.logger.info("entering BLINK state")
      self.moveEnabled = true
      self.startDestinationsVisited = 0
   end
end

function TutorialState:setNewTrigger(x, y)
   local cell = self.level:getCell(x, y)
   cell:give(prism.components.Trigger())
   self:highlightCell(x, y)
end


function TutorialState:highlightCell(x, y)
   local drawable = self.level:getCell(x, y):expect(prism.components.Drawable)
   self.highlightBG = drawable.background:copy()

   drawable.background = prism.Color4.GREEN

   -- self.level:yield(prism.messages.AnimationMessage({
   --    animation = spectrum.animations.Pulse(x, y, prism.Color4.BLACK, prism.Color4.GREEN, 0.5),
   --    blocking = false,
   --    skippable = false
   -- }))
end

function TutorialState:unhighlightCell(x, y)
   local cell = self.level:getCell(x, y)
   local drawable = cell:expect(prism.components.Drawable)

   if self.highlightBG then
      drawable.background = self.highlightBG
   else
      drawable.background = prism.Color4.BLACK
   end

   cell:remove(prism.components.Trigger)
end

function TutorialState:setRandomTrigger()
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

return TutorialState
