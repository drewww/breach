local controls = require "controls"

--- @class TutorialState : PlayState, System
--- @overload fun(display: Display, overlayDisplay: Display, step: string): TutorialState
local TutorialState = spectrum.gamestates.PlayState:extend "TutorialState"

-- System interface requirements
TutorialState.requirements = {}
TutorialState.softRequirements = {}

-- TODO some data structure that holds a list of valid steps.

--- @param display Display
--- @param overlayDisplay Display
--- @param step string
function TutorialState:__new(display, overlayDisplay, step)
   prism.logger.info("CONSTRUCT TUTORIAL STATE")

   local map = step or "start"

   -- if there's an underscore in the step, strip after the underscore
   local underscore_pos = string.find(map, "_")
   if underscore_pos then
      map = string.sub(map, 1, underscore_pos - 1)
   end

   local builder = prism.LevelBuilder.fromLz4("modules/game/world/prefab/tutorial/" .. map .. ".lvl")

   builder:addSystems(self)

   -- Place the player character at a starting location
   local player = prism.actors.Player()

   if step == "melee" or map == "melee" then
      builder:addActor(player, 5, 5)
   elseif step == "ranged" then
      builder:addActor(player, 9, 5)
   else
      builder:addActor(player, 3, 3)
   end

   self.super.__new(self, display, overlayDisplay, builder)

   self.dialog = player:expect(prism.components.Dialog)

   self.startDestinationsVisited = 0
   self.botsKilled = 0
   self.survivalTurns = 0

   -- Wave-based spawning for ranged step
   self.currentWave = 0
   self.enemiesInCurrentWave = 0

   -- Define waves: each entry is a list of enemy types to spawn
   self.waves = {
      { "BurstBot", "BurstBot" },                                    -- Wave 1: 2 burst bots
      { "LaserBot" },                                                -- Wave 2: 1 laser bot
      { "BurstBot", "BurstBot", "LaserBot" },                        -- Wave 3: 2 burst, 1 laser
      { "BurstBot", "LaserBot", "LaserBot" },                        -- Wave 4: 1 burst, 2 laser
      { "BurstBot", "BurstBot", "LaserBot", "LaserBot" },            -- Wave 5: 2 burst, 2 laser
      { "BurstBot", "BurstBot", "BurstBot", "LaserBot", "LaserBot" } -- Wave 6: 3 burst, 2 laser
   }

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
      prism.logger.info("DISMISS (dialog=", self.dialog:size(), ")")
      if self.step == "start" and self.dialog:size() == 1 then
         self:setStep("move")
      elseif self.step == "post-move" and self.dialog:size() == 0 then
         self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "blink"))
      elseif self.step == "post-blink" and self.dialog:size() == 0 then
         self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "melee"))
      elseif self.step == "melee_pushpre" and self.dialog:size() == 0 then
         self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "melee_push"))
      elseif self.step == "melee_pushpost" and self.dialog:size() == 0 then
         self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "ranged"))
      end
   elseif self.moveEnabled then
      self.super.updateDecision(self, dt, owner, decision)
   end
end

function TutorialState:setStep(step)
   -- TODO validate against step map
   self.step = step

   prism.logger.info("STEP enter: ", step)
   self.botsKilled = 0

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
      self.dialog:clear()

      self.dialog:push("Avoid the red spaces. Hold SHIFT+(W,A,S,D) to engage your BLINK device.")
      -- TODO should be undismissable eventually.
   elseif step == "post-blink" then
      self.moveEnabled = false
   elseif step == "melee" then
      self.dialog:clear()

      self.dialog:push(
         "Combat safeties released. Start with your impact pistol. Low damage, but if you're clever you'll make it work.")

      self.dialog:push("One enemy to start.")
      local bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 6, 3)


      self.moveEnabled = true
   elseif step == "melee_2" then
      self.dialog:clear()

      self.dialog:push(
         "Easy. Now, show me you can hold off two at once.")

      local bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 6, 5)


      bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 2, 6)

      self.moveEnabled = true
   elseif step == "melee_3" then
      self.dialog:clear()
      self.dialog:push(
         "Okay, now five at once.")

      local bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 6, 4)

      bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 2, 2)

      bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 10, 6)

      bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 6, 10)

      self.moveEnabled = true
   elseif step == "melee_pushpre" then
      self.dialog:clear()
      self.moveEnabled = false
      self.dialog:push(
         "Now, I've disabled your weapon's damage. You can only kill by pushing the bots into a wall. Also, you must now RELOAD your weapon by pressing R when out of ammo.")
   elseif step == "melee_push" then
      self.moveEnabled = true
      self.dialog:clear()

      self.dialog:push(
         "Remember, you can only cause damage by pushing into a wall or other bot.")

      local bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 6, 4)

      bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 2, 2)

      bot = prism.actors.TrainingBurstBot()
      self.level:addActor(bot, 10, 6)
   elseif step == "melee_pushpost" then
      self.moveEnabled = false
      self.dialog:clear()

      self.dialog:push(
         "Remember this skill; in the field you will have limited ammunition and many targets. Environmental kills are highly efficient.")
      self.dialog:push(
         "Prepare for your final survival trial against fully armed bots.")
   elseif step == "ranged" then
      self.moveEnabled = true
      self.dialog:clear()

      self.dialog:push(
         "Survive as long as you can. Enemies will spawn in waves. Clear each wave to progress. Expect new enemy types as you progress.")

      self.survivalTurns = 0
      self.currentWave = 0
      self.enemiesInCurrentWave = 0

      local player = self.level:query(prism.components.PlayerController):first()

      assert(player)

      player:remove(prism.components.Inventory)

      local inventory = prism.components.Inventory()
      player:give(inventory)

      local pistol = prism.actors.Pistol()
      pistol:give(prism.components.Active())
      inventory:addItem(AMMO_TYPES["Pistol"](500))

      inventory:addItem(pistol)

      -- Start wave 1
      self:spawnWave()
   end

   if string.find(step, "melee") then
      -- setup player inventory
      local player = self.level:query(prism.components.PlayerController):first()

      assert(player)

      player:remove(prism.components.Inventory)

      local inventory = prism.components.Inventory()
      player:give(inventory)

      local pistol
      if step == "melee_push" then
         pistol = prism.actors.PushPistol()
         pistol:give(prism.components.Active())
         inventory:addItem(AMMO_TYPES["Pistol"](500))
      else
         pistol = prism.actors.InfinitePistol()
         pistol:give(prism.components.Active())
      end

      inventory:addItem(pistol)
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

-- System interface methods

function TutorialState:initialize(level)
   -- Called when the Level is initialized
end

function TutorialState:postInitialize(level)
   -- Called after the Level is initialized
end

function TutorialState:beforeAction(level, actor, action)
   -- Called before an actor executes an action
end

function TutorialState:afterAction(level, actor, action)
   -- Called after an actor has taken an action
end

function TutorialState:beforeMove(level, actor, from, to)
   -- Called before an actor moves
end

function TutorialState:onMove(level, actor, from, to)
   local cellMovedInto = self.level:getCell(to:decompose())

   if self.step == "move" or self.step == "blink" and actor:has(prism.components.PlayerController) then
      if cellMovedInto:has(prism.components.Trigger) then
         local trigger = cellMovedInto:expect(prism.components.Trigger)
         if trigger.type == "danger" then
            self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "blink"))
         else
            self.startDestinationsVisited = self.startDestinationsVisited + 1

            self:unhighlightCell(to:decompose())

            if self.startDestinationsVisited > 1 and self.step == "blink" then
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

function TutorialState:onActorAdded(level, actor)
   -- Called after an actor has been added to the Level
end

function TutorialState:onActorRemoved(level, actor)
   prism.logger.info("actor died: ", actor:getName())
   if actor:has(prism.components.PlayerController) then
      prism.logger.info("PLAYER DIED")

      -- rest to the current step
      self:getManager():enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, self.step))
   end

   if self.step == "melee" and actor:has(prism.components.BehaviorController) then
      self:setStep("melee_2")
   elseif self.step == "melee_2" and actor:has(prism.components.BehaviorController) then
      self.botsKilled = self.botsKilled + 1

      if self.botsKilled == 2 then
         self:setStep("melee_3")
      end
   elseif self.step == "melee_3" and actor:has(prism.components.BehaviorController) then
      self.botsKilled = self.botsKilled + 1

      if self.botsKilled == 4 then
         self:setStep("melee_pushpre")
      end
   elseif self.step == "melee_push" and actor:has(prism.components.BehaviorController) then
      self.botsKilled = self.botsKilled + 1

      if self.botsKilled == 3 then
         self:setStep("melee_pushpost")
      end
   elseif self.step == "ranged" and actor:has(prism.components.BehaviorController) then
      -- Track enemy deaths in wave-based mode
      self.enemiesInCurrentWave = self.enemiesInCurrentWave - 1
      prism.logger.info("Enemy killed. Remaining in wave: ", self.enemiesInCurrentWave)
   end

   prism.logger.info("bots killed: ", self.botsKilled)
end

function TutorialState:onComponentAdded(level, actor, component)
end

function TutorialState:onComponentRemoved(level, actor, component)
end

function TutorialState:afterOpacityChanged(level, x, y)
   -- Called when opacity changes at a tile
end

function TutorialState:onTick(level)
   -- Called every 100 units of time
end

function TutorialState:onTurn(level, actor)
   -- Called when a new turn begins
end

function TutorialState:onTurnEnd(level, actor)
   -- Called when a turn ends
   if actor:has(prism.components.PlayerController) and self.step == "ranged" then
      self.survivalTurns = self.survivalTurns + 1

      -- Check if wave is cleared and spawn next wave
      if self.enemiesInCurrentWave == 0 and self.currentWave < #self.waves then
         self.dialog:push("Wave " .. self.currentWave .. " cleared. Prepare for wave " .. (self.currentWave + 1) .. ".")
         self:spawnWave()
      elseif self.enemiesInCurrentWave == 0 and self.currentWave == #self.waves then
         self.dialog:push("All waves cleared. Training complete.")
      end
   end
end

function TutorialState:onYield(level, event)
   -- Called whenever the level yields back to the interface
end

function TutorialState:spawnWave()
   self.currentWave = self.currentWave + 1

   if self.currentWave > #self.waves then
      prism.logger.info("All waves completed!")
      return
   end

   local wave = self.waves[self.currentWave]
   self.enemiesInCurrentWave = #wave

   prism.logger.info("Spawning wave ", self.currentWave, " with ", self.enemiesInCurrentWave, " enemies")

   local spawnPoints = {
      prism.Vector2(10, 3),
      prism.Vector2(3, 10),
      prism.Vector2(17, 10),
      prism.Vector2(10, 17),
      prism.Vector2(10, 10)
   }

   -- Spawn each enemy in the wave
   for _, enemyType in ipairs(wave) do
      -- Find open spawn points
      local openPoints = {}
      for _, point in ipairs(spawnPoints) do
         if self.level:getCellPassable(point.x, point.y, prism.Collision.createBitmaskFromMovetypes({ "walk" })) then
            table.insert(openPoints, point)
         end
      end

      if #openPoints > 0 then
         local point = openPoints[math.random(1, #openPoints)]
         local bot

         if enemyType == "BurstBot" then
            bot = prism.actors.BurstBot()
         elseif enemyType == "LaserBot" then
            bot = prism.actors.LaserBot()
         end

         if bot then
            self.level:addActor(bot, point:decompose())
         end
      end
   end
end

return TutorialState
