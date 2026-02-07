local controls = require "controls"
local helpers = require "util.helpers"

--- @class PlayState : OverlayLevelState
--- A custom game level state responsible for initializing the level map,
--- handling input, and drawing the state to the screen.
---
--- @overload fun(display: Display, overlayDisplay: Display, builder?: LevelBuilder): PlayState
local PlayState = spectrum.gamestates.OverlayLevelState:extend "PlayState"
--- @param display Display
--- @param overlayDisplay Display
--- @param builder? LevelBuilder if a string, load a prefab with that string. If a LevelBuilder, just pass it through.
function PlayState:__new(display, overlayDisplay, builder)
   -- Construct a
   --  simple test map using MapBuilder.
   -- In a complete game, you'd likely extract this logic to a separate module
   -- and pass in an existing player object between levels.
   -- local builder = prism.LevelBuilder()
   local defaultSetup = false
   if builder then
      prism.logger.info("Using passed pre-built map.")
   else
      prism.logger.info("No map passed to PlayState, initializing with default room.")
      defaultSetup = true
      builder = prism.LevelBuilder()
      builder:rectangle("line", 0, 0, 32, 32, prism.cells.Wall)
      -- Fill the interior with floor tiles
      builder:rectangle("fill", 1, 1, 31, 31, prism.cells.Floor)
      -- Add a small block of walls within the map
      builder:rectangle("fill", 5, 5, 7, 7, prism.cells.Wall)
      -- Add a pit area to the southeast
      builder:rectangle("fill", 20, 20, 25, 25, prism.cells.Pit)

      -- Place the player character at a starting location
      local player = prism.actors.Player()
      builder:addActor(player, 9, 9)
   end


   -- Add systems
   builder:addSystems(prism.systems.SensesSystem(), prism.systems.SightSystem(),
      prism.systems.DiffusionSystem(),
      prism.systems.EnergySystem())

   builder:addTurnHandler(prism.turnhandlers.IntenfulTurnHandler())

   --- @type Vector2[]
   self.dashDestinationLocations = {}

   --- @type Vector2?
   self.mouseCellPosition = nil
   self.mouseCellPositionChanged = false
   self.mouseOverActor = nil


   self.firing = false
   self.lastTargetCount = 0

   -- key: actor, value: Animation[]
   self.actorAnimations = {}

   -- Initialize with the created level and display, the heavy lifting is done by
   -- the parent class.
   spectrum.gamestates.OverlayLevelState.__new(self, builder:build(prism.cells.Wall), display, overlayDisplay)

   spectrum.gamestates.OverlayLevelState.addPanel(self,
      HealthPanel(overlayDisplay, prism.Vector2(2, (SCREEN_HEIGHT - 1) * 2)))
   spectrum.gamestates.OverlayLevelState.addPanel(self,
      ItemPanel(overlayDisplay, prism.Vector2(22, (SCREEN_HEIGHT - 1) * 2)))

   spectrum.gamestates.OverlayLevelState.addPanel(self, DialogPanel(overlayDisplay, prism.Vector2(3, 3)))

   spectrum.gamestates.OverlayLevelState.addPanel(self,
      EnergyPanel(overlayDisplay, prism.Vector2(14, (SCREEN_HEIGHT - 1) * 2)))

   if defaultSetup then
      local weapons = {}
      table.insert(weapons, prism.actors.Shotgun())
      table.insert(weapons, prism.actors.Pistol())
      table.insert(weapons, prism.actors.Laser())
      table.insert(weapons, prism.actors.Grenade(3))
      table.insert(weapons, prism.actors.SmokeGrenade(3))

      local player = self.level:query(prism.components.PlayerController):first()

      assert(player, "No player found in level.")

      for i, weapon in ipairs(weapons) do
         if i == 1 then
            weapon:give(prism.components.Active())
         end

         player:expect(prism.components.Inventory):addItem(weapon)
      end

      player:expect(prism.components.Inventory):addItem(AMMO_TYPES["Pistol"](50))
   end

   self.mouseCellPosition = prism.Vector2(1, 1)
end

function PlayState:handleMessage(message)
   -- TODO migrate this over to TutorialState
   -- if prism.messages.TutorialLoadMapMessage:is(message) then
   --    ---@cast message TutorialLoadMapMessage

   --    prism.logger.info("processing load map message: ", message.map)

   --    self.manager:enter(spectrum.gamestates.PlayState(self.display, self.overlayDisplay, "tutorial", message.map))
   -- end
   --
   spectrum.gamestates.OverlayLevelState.handleMessage(self, message)

   -- Handle any messages sent to the level state from the level. LevelState
   -- handles a few built-in messages for you, like the decision you fill out
   -- here.

   -- This is where you'd process custom messages like advancing to the next
   -- level or triggering a game over.
end

function PlayState:clearAllDashDestinationTiles()
   self.dashDestinationLocations = {}
end

function PlayState:trySetDashDestinationTiles(level, actor)
   if not controls.dash_mode.down then
      return
   end

   self:clearAllDashDestinationTiles()

   -- highlight the 8 2x distance neighbors
   for _, vec in pairs(RULES.dashLocations(level, actor)) do
      local destination = vec
      table.insert(self.dashDestinationLocations, destination)
   end
end

--- Checks if the player can use an ability on a target position.
--- This wraps the ability's internal methods for consistent validation across UI and gameplay.
--- @param player Actor
--- @param activeItem Actor
--- @param targetPosition Vector2
--- @return boolean
function PlayState:canUseAbility(player, activeItem, targetPosition)
   if not player or not activeItem or not targetPosition then
      return false
   end

   local direction = targetPosition - player:getPosition()
   local ability = prism.actions.ItemAbility(player, activeItem, direction)

   local costLegal, cooldownLegal = ability:canFire(self.level)
   local rangeLegal, seesLegal, pathsLegal, targetContainsPlayerIfNecessary = ability:canTarget(self.level)

   return costLegal and cooldownLegal and rangeLegal and seesLegal and pathsLegal and targetContainsPlayerIfNecessary
end

-- updateDecision is called whenever there's an ActionDecision to handle.
function PlayState:updateDecision(dt, owner, decision)
   -- Controls need to be updated each frame.
   controls:update()

   local player = self.level:query(prism.components.PlayerController):first()

   if not player then return end

   local inventory = player:expect(prism.components.Inventory)

   if controls.dash_mode.pressed or controls.dash_mode.down then
      self:trySetDashDestinationTiles(self.level, owner)
   end

   if controls.dash_mode.released then
      self:clearAllDashDestinationTiles()
   end

   -- Controls are accessed directly via table index.
   if controls.move.pressed and not controls.dash_mode.down then
      local move = prism.actions.Move(owner, controls.move.vector, false)

      if self:setAction(move) then
         return
      end
   end

   if controls.dash_mode.down and owner:has(prism.components.Dasher) and controls.move.pressed then
      local dashC = owner:expect(prism.components.Dasher)

      local dest = RULES.dashLocations(self.level, owner)[controls.move.vector]

      if dest and self.level:inBounds(dest:decompose()) then
         -- otherwise, continue
         local dash = prism.actions.Dash(owner, dest)

         local success, err = self:setAction(dash)
         if success then
            self:clearAllDashDestinationTiles()
            return
         end
      end
   end

   if controls.reload.pressed then
      local item = inventory:query(prism.components.Ability, prism.components.Active):first()

      local reload = prism.actions.Reload(player, item, false)
      local s, e = self:setAction(reload)
      prism.logger.info("reload: ", s, e)
   end

   if controls.cycle.pressed then
      local i = 0
      local stopAt = -1
      local items = inventory:query(prism.components.Ability)

      ---@type Actor
      local firstItem = items:first()

      for item in items:iter() do
         if item:has(prism.components.Active) then
            stopAt = i + 1
            item:remove(prism.components.Active)
         end

         if i == stopAt then
            item:give(prism.components.Active())
            break
         end

         if i == #items:gather() - 1 then
            firstItem:give(prism.components.Active())
         end

         i = i + 1
      end

      -- Update component cache for all items after component changes
      for item in items:iter() do
         inventory.inventory:updateComponentCache(item)
      end
   end

   if controls.use.pressed then
      if self.mouseCellPosition and player and not controls.dash_mode.down then
         self.firing = true
         local activeItem = player:expect(prism.components.Inventory):query(prism.components.Ability,
            prism.components.Active):first()

         if activeItem and self:canUseAbility(player, activeItem, self.mouseCellPosition) then
            local ranges = activeItem:expect(prism.components.Range)
            local pos = TEMPLATE.adjustPositionForRange(player, self.mouseCellPosition, ranges)

            local ability = prism.actions.ItemAbility(owner, activeItem, pos - owner:getPosition())

            local s, e = self:setAction(ability)
            prism.logger.info("ability: ", s, e)
         end
      end
   end

   if controls.dismiss.pressed then
      local dialog = player:expect(prism.components.Dialog)

      dialog:pop()
   end

   if controls.wait.pressed then self:setAction(prism.actions.Wait(owner)) end
end

function PlayState:draw()
   self.display:clear()
   self.overlayDisplay:clear()

   -- prism.logger.info("---------")
   -- prism.logger.info("cursor: ", self.mouseCellPosition)

   -- prism.logger.info("actors at cursor: ")
   -- local actors = self.level:query():at(self.mouseCellPosition:decompose()):iter()
   -- for actor in actors do
   --    prism.logger.info("actor: ", actor:getName())
   -- end

   local player = self.level:query(prism.components.PlayerController):first()

   if not player then
      -- You would normally transition to a game over state
      self.display:putLevel(self.level)
      return
   end

   local position = player:expectPosition()

   local x, y = self.display:getCenterOffset(position:decompose())
   self.display:setCamera(x, y)
   self.overlayDisplay:setCamera(4 * x, 2 * y)

   local primary, secondary = self:getSenses()
   -- Render the level using the player’s senses
   self.display:beginCamera()
   self.display:putSenses(primary, secondary, self.level)
   self.display:endCamera()

   self.overlayDisplay:beginCamera()
   self.overlayDisplay:putAnimations(self.level, primary[1])
   self.overlayDisplay:endCamera()

   -- custom terminal drawing goes here!

   self.display:beginCamera()
   for _, pos in ipairs(self.dashDestinationLocations) do
      self.display:putBG(pos.x, pos.y, prism.Color4.BLUE, math.huge)
   end

   -- Get player's senses to filter visible tiles
   local playerSenses = player:get(prism.components.Senses)


   -- Collect and sort actors so mouseOverActor is last
   local actorsWithControllers = {}
   for actor, controller in self.level:query(prism.components.Controller):iter() do
      table.insert(actorsWithControllers, { actor = actor, controller = controller })
   end
   table.sort(actorsWithControllers, function(a, b)
      if a.actor == self.mouseOverActor then return false end
      if b.actor == self.mouseOverActor then return true end
      return false
   end)

   for _, entry in ipairs(actorsWithControllers) do
      local actor = entry.actor
      local controller = entry.controller
      ---@cast controller Controller
      ---@cast controller +IIntentful
      local intent = controller.intent
      if intent then
         if prism.actions.Fly:is(intent) or prism.actions.Move:is(intent) then
            local destinations = {}

            if prism.actions.Fly:is(intent) then
               ---@cast intent Fly
               destinations = intent:getDestinations()
            else
               ---@cast intent Move
               table.insert(destinations, intent:getDestination())
            end

            for _, pos in ipairs(destinations) do
               -- Only show if player can see this tile
               if not playerSenses or playerSenses.cells:get(pos.x, pos.y) then
                  self:blendBG(pos.x, pos.y, self:highlightIntent(actor) and C.MOVE_INTENT or C.MOVE_INTENT_DARK,
                     self.display)
               end
            end
         end

         if prism.actions.ItemAbility:is(intent) then
            ---@cast intent ItemAbility

            local targets = intent:getTriggerCells()

            local color, color_dark = C.SHOOT_INTENT, C.SHOOT_INTENT_DARK
            if intent:getItem():has(prism.components.Trigger) then
               color, color_dark = C.TRIGGER_INTENT, C.TRIGGER_INTENT_DARK
            end

            for _, pos in ipairs(targets) do
               -- Only show if player can see this tile
               if playerSenses and playerSenses.cells:get(pos.x, pos.y) then
                  -- okay, if the item has a trigger, render with WATCH_INTENT not SHOOT_INTENT.

                  self:blendBG(pos.x, pos.y, self:highlightIntent(actor) and color or color_dark,
                     self.display)
               end
            end
         end
      end
   end

   local activeItems = player:expect(prism.components.Inventory):query(prism.components.Ability,
      prism.components.Active)
   local activeItem = activeItems:first()

   if self.mouseCellPosition then
      if player then
         -- Cache the ability validation result since we use it multiple times in this draw call
         local canUse = false
         if activeItem then
            canUse = self:canUseAbility(player, activeItem, self.mouseCellPosition)

            -- Show "EMPTY" message if we can't use due to ammo
            if not canUse then
               local clip = activeItem:get(prism.components.Clip)
               local cost = activeItem:get(prism.components.Cost)
               if clip and cost and cost.ammo > 0 and clip.ammo < cost.ammo then
                  local ox, oy = spectrum.gamestates.OverlayLevelState.getOverlayPosUnderMouse(self)
                  self.overlayDisplay:beginCamera()
                  self.overlayDisplay:print(ox + 2, oy, "EMPTY", prism.Color4.BLACK,
                     prism.Color4.YELLOW)
                  self.overlayDisplay:endCamera()
               end
            end

            local effect = activeItem:expect(prism.components.Effect)
            local template = activeItem:expect(prism.components.Template)

            if effect.push > 0 then
               local ranges = activeItem:get(prism.components.Range)
               local pos = self.mouseCellPosition:copy()
               if ranges then
                  pos = TEMPLATE.adjustPositionForRange(player, pos, ranges)
               end

               -- Get all actual impact positions (handles multishot per-pellet targeting)
               local impactPositions = TEMPLATE.getAllImpactPositions(self.level, player, activeItem, pos)

               -- Get multi-shot count for push prediction
               local cost = activeItem:get(prism.components.Cost)
               local multi = 1
               if cost and cost.multi then
                  multi = cost.multi
               end

               -- Track which actors have been processed to avoid duplicate push visualizations
               local processedActors = {}

               for _, impactPos in ipairs(impactPositions) do
                  local actor = self.level:query(prism.components.Collider):at(impactPos:decompose()):first()

                  if actor and canUse and (playerSenses and playerSenses.cells:get(impactPos:decompose())) then
                     -- For multishot, each pellet can push; for regular multi, multiply push
                     -- Only show push visualization once per actor
                     if not processedActors[actor] then
                        processedActors[actor] = true

                        local push = effect.push * multi
                        local vector = effect:getPushVector(actor, player, impactPos)
                        -- route through the action target rules to confirm that this is legal. Though we will not actually use this action for anything.
                        local action = prism.actions.Push(player, actor, vector, push,
                           false)
                        local success, err = self.level:canPerform(action)

                        if success then
                           -- TODO do not calculate push result twice; calculate it once above in the action and store it in a field that gets pulled out here.
                           -- local pushResult, totalSteps = RULES.pushResult(self.level, actor, vector, effect.push)

                           for index, result in ipairs(action.results) do
                              local lastStep = index == action.steps

                              if not result.collision then
                                 local char = actor:expect(prism.components.Drawable).index
                                 local color = prism.Color4.DARKGREY
                                 if lastStep then
                                    color = prism.Color4.GREY
                                 end
                                 self.display:put(result.pos.x, result.pos.y, char, color, prism.Color4.TRANSPARENT)
                              else
                                 self.display:put(result.pos.x, result.pos.y, "x",
                                    prism.Color4.RED,
                                    prism.Color4.TRANSPARENT)
                              end
                           end
                        end
                     end
                  end
               end
            end

            if not self.firing and canUse then
               local ranges = activeItem:get(prism.components.Range)
               local pos = self.mouseCellPosition:copy()

               if ranges then
                  pos = TEMPLATE.adjustPositionForRange(player, pos, ranges)
               end

               -- Get all actual impact positions (handles multishot per-pellet targeting)
               local impactPositions = TEMPLATE.getAllImpactPositions(self.level, player, activeItem, pos)

               self.overlayDisplay:beginCamera()
               for _, impactPos in ipairs(impactPositions) do
                  self:blendBG(impactPos.x, impactPos.y, prism.Color4.BLUE:lerp(prism.Color4.BLACK, 0.5), self.display)
               end
               self.overlayDisplay:endCamera()
            end
         end
      end

      self:drawHealthBars(playerSenses)

      -- This was the old bounce test code. Retaining for postering.
      -- local vector = self.mouseCellPosition - player:getPosition()
      -- local bounces = RULES.bounce(self.level, player:getPosition(), 20, math.atan2(vector.y, vector.x))

      -- local playerSense = player:expect(prism.components.Senses)

      -- for i, bounce in ipairs(bounces) do
      --    local cell = self.level:getCell(bounce.pos.x, bounce.pos.y)

      --    -- local seenByPlayer = self.level:getCell(bounce.pos.x, bounce.pos.y):hasRelation(
      --    -- prism.relations.SensedByRelation, player)

      --    local seenByPlayer = playerSense.cells:get(bounce.pos.x, bounce.pos.y)

      --    if seenByPlayer then
      --       self.display:putBG(bounce.pos.x, bounce.pos.y, prism.Color4.BLACK:lerp(prism.Color4.YELLOW, i / 20),
      --          math.huge)
      --    else
      --       break
      self.display:endCamera()

      -- Render a background for the bottom overlay panel.
      self.overlayDisplay:rectangle("fill", 0, SCREEN_HEIGHT * 2 - 2, SCREEN_WIDTH * 4 + 1, 3, " ",
         prism.Color4.TRANSPARENT,
         C.UI_BACKGROUND)
      spectrum.gamestates.OverlayLevelState.putPanels(self)

      -- Actually render the terminal out and present it to the screen.
      -- You could use love2d to translate and say center a smaller terminal or
      -- offset it for custom non-terminal UI elements. If you do scale the UI
      -- just remember that display:getCellUnderMouse expects the mouse in the
      -- display's local pixel coordinates
      self.display:draw()
      self.overlayDisplay:draw()

      -- self.super.draw(self)

      -- If you don't explicitly put the animations, they wont' run.
      -- I'd like this to be somewhere else in the stack (i.e. in the superclass)
      -- so you can't forget but I couldn't get that to work.

      -- custom love2d drawing goes here!
   end
end

-- for every actor with a health component, accumulate any damage they are set to take.
-- damage comes from: the player's current template location
-- any AbilityIntent that deals damage.
-- should we be doing this for push damage as well? accumulate total effects?
-- for now let's just do damage.

---@param playerSenses Senses
function PlayState:drawHealthBars(playerSenses)
   -- for now it's an integer summing up damage, later can expand to other effects
   local actorsReceivingEffects = {}

   -- Accumulate damage for a single impact position (used for both regular and multishot weapons)
   local accumulateDamageAtPosition = function(pos, effect, owner, impactPoint)
      local actor = self.level:query(prism.components.Health):at(pos.x, pos.y):first()

      if actor and playerSenses.cells:get(pos:decompose()) and actor ~= owner then
         if not actorsReceivingEffects[actor] then
            actorsReceivingEffects[actor] = 0
         end

         -- compute the effects of the push, and if it adds damage.
         local vector = effect:getPushVector(actor, owner, impactPoint)
         -- route through the action target rules to confirm that this is legal. Though we will not actually use this action for anything.
         local action = prism.actions.Push(owner, actor, vector, effect.push,
            false)
         local success, err = self.level:canPerform(action)

         if action.collision then
            actorsReceivingEffects[actor] = actorsReceivingEffects[actor] + COLLISION_DAMAGE
         end

         actorsReceivingEffects[actor] = actorsReceivingEffects[actor] + effect.health
      end
   end

   -- loop through a given effect and apply its effects on every target inside the template
   local processEffectOnCells = function(targets, effect, owner, impactPoint)
      for _, target in ipairs(targets) do
         accumulateDamageAtPosition(target, effect, owner, impactPoint)
      end
   end

   -- HANDLE ACTIVE PLAYER ITEM DAMAGE
   local player = self.level:query(prism.components.PlayerController):first()

   if not player then return end

   local activeItem = player:expect(prism.components.Inventory):query(prism.components.Ability,
      prism.components.Active):first()

   if activeItem then
      local template = activeItem:expect(prism.components.Template)
      local effect = activeItem:expect(prism.components.Effect)
      local cost = activeItem:get(prism.components.Cost)
      local clip = activeItem:get(prism.components.Clip)

      if effect.health or effect.push then
         -- Use canUseAbility for consistent validation
         if self:canUseAbility(player, activeItem, self.mouseCellPosition) then
            -- Get multi-shot count for damage prediction
            local multi = 1
            if cost and cost.multi then
               multi = cost.multi
            end

            -- Get all actual impact positions (handles multishot per-pellet targeting)
            local impactPositions = TEMPLATE.getAllImpactPositions(self.level, player, activeItem,
               self.mouseCellPosition)

            -- Process each shot's effect
            for shot = 1, multi do
               -- For multishot weapons, each position is an individual pellet impact
               -- For regular weapons, positions are the template area
               for _, impactPos in ipairs(impactPositions) do
                  accumulateDamageAtPosition(impactPos, effect, player, impactPos)
               end
            end
         end
      end
   end

   -- HANDLE INTENTS
   for actor, controller in self.level:query(prism.components.BehaviorController):iter() do
      ---@cast controller BehaviorController
      if controller.intent then
         if prism.actions.ItemAbility:is(controller.intent) then
            local action = controller.intent

            ---@cast action ItemAbility
            local item = action:getItem()
            local effect = item:expect(prism.components.Effect)

            if effect.health then
               -- get actors that will be effected by this action
               local item = action:getItem()
               local intendedTarget = action:getTargeted(2) + actor:getPosition()

               -- Get all actual impact positions (handles multishot per-pellet targeting)
               local impactPositions = TEMPLATE.getAllImpactPositions(self.level, actor, item, intendedTarget)

               for _, impactPos in ipairs(impactPositions) do
                  accumulateDamageAtPosition(impactPos, effect, actor, impactPos)
               end
            end
         end
      end
   end

   -- now render out the effects
   self.overlayDisplay:beginCamera()
   for actor, damage in pairs(actorsReceivingEffects) do
      if actor then
         local health = actor:expect(prism.components.Health)
         local healthValue = health.value
         local target = actor:getPosition()

         if damage > 0 then
            local postDamageHealth = healthValue - damage

            local tx = (target.x - 1) * 4
            local ty = (target.y) * 2

            local tiles = helpers.calculateHealthBarTiles(healthValue, postDamageHealth)

            for i, tile in ipairs(tiles) do
               self.overlayDisplay:put(tx + i, ty, tile.index, tile.fg, tile.bg, math.huge)
            end
         end
      end
   end
   self.overlayDisplay:endCamera()
end

function PlayState:mousemoved()
   local cellX, cellY, targetCell = self:getCellUnderMouse()
   local pos = prism.Vector2(cellX, cellY)

   if self.mouseCellPosition ~= pos then
      self.mouseCellPosition = prism.Vector2(cellX, cellY)
      self.firing = false

      -- see if there's an actor there to track
      self.mouseOverActor = self.level:query(prism.components.BehaviorController):at(self.mouseCellPosition:decompose())
          :first()
   end
end

function PlayState:highlightIntent(actor)
   if self.mouseOverActor then
      return self.mouseOverActor == actor
   else
      return true
   end
end

function PlayState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.SensesSystem):postInitialize(self.level)
end

return PlayState
