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
function PlayState:__new(display, overlayDisplay, builder, existingPlayer)
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

      -- Add existing player if provided, otherwise a new one will be created
      if existingPlayer then
         builder:addActor(existingPlayer, 16, 16)
      else
         -- Create a new player for default setup
         local player = prism.actors.Player()
         builder:addActor(player, 16, 16)
      end
   end


   -- Add systems
   builder:addSystems(prism.systems.SensesSystem(), prism.systems.SightSystem(),
      prism.systems.DiffusionSystem(),
      prism.systems.EnergySystem(),
      prism.systems.TickSystem())

   builder:addTurnHandler(prism.turnhandlers.IntenfulTurnHandler())

   --- @type Vector2[]
   self.dashDestinationLocations = {}

   --- @type Vector2?
   self.mouseCellPosition = nil
   self.mouseCellPositionChanged = false
   self.mouseOverNPC = nil


   self.firing = false
   self.lastTargetCount = 0

   -- key: actor, value: Animation[]
   self.actorAnimations = {}

   -- Initialize with the created level and display, the heavy lifting is done by
   -- the parent class.
   spectrum.gamestates.OverlayLevelState.__new(self, builder:build(prism.cells.Wall), display, overlayDisplay)

   -- Compute wall-distance map for the level (only for generated levels)
   if not defaultSetup then
      local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"
      self.level.wallDistanceMap = TunnelWorldGenerator.computeWallDistanceMap(self.level)
   end

   PANEL_Y = SCREEN_HEIGHT * 2 - 6
   PANEL_HEIGHT = 10

   -- spectrum.gamestates.OverlayLevelState.addPanel(self,
   --    HealthPanel(overlayDisplay, prism.Vector2(2, PANEL_Y)))
   -- spectrum.gamestates.OverlayLevelState.addPanel(self,
   --    HealthPanel(overlayDisplay, prism.Vector2(2, PANEL_Y)))
   spectrum.gamestates.OverlayLevelState.addPanel(self,
      spectrum.panels.ItemPanel(overlayDisplay, prism.Vector2(38, PANEL_Y), display))

   spectrum.gamestates.OverlayLevelState.addPanel(self, spectrum.panels.DialogPanel(overlayDisplay, prism.Vector2(3, 3)))

   spectrum.gamestates.OverlayLevelState.addPanel(self,
      spectrum.panels.PlayerPanel(overlayDisplay, prism.Vector2(SCREEN_WIDTH * 4 - 20, PANEL_Y)))

   self.targetPanel = spectrum.panels.TargetPanel(display, overlayDisplay, prism.Vector2(1, PANEL_Y))
   spectrum.gamestates.OverlayLevelState.addPanel(self,
      self.targetPanel)


   if defaultSetup then
      -- Only set up default weapons if we're not using an existing player
      if not existingPlayer then
         local weapons = {}
         table.insert(weapons, prism.actors.Shotgun())
         table.insert(weapons, prism.actors.Pistol())
         table.insert(weapons, prism.actors.Laser())
         table.insert(weapons, prism.actors.SmokeGrenade(3))

         local player = self.level:query(prism.components.PlayerController):first()

         assert(player, "No player found in level.")

         helpers.defaultWeaponLoad(player)
      end
   end

   self.mouseCellPosition = prism.Vector2(1, 1)
end

function PlayState:handleMessage(message)
   --
   spectrum.gamestates.OverlayLevelState.handleMessage(self, message)

   -- Handle any messages sent to the level state from the level. LevelState
   -- handles a few built-in messages for you, like the decision you fill out
   -- here.

   if prism.messages.DescendMessage:is(message) then
      -- Extract the player before transitioning
      local player = message.descender

      if player then
         prism.logger.info("Descending to next floor with existing player")

         local playerC = player:get(prism.components.Player)

         if playerC then
            playerC.level = playerC.level + 1

            prism.logger.info("descending to ", playerC.level)
            Audio.playNextLevel()
            if playerC.level >= 6 then
               self.manager:enter(spectrum.gamestates.VictoryState(self.display, self.overlayDisplay, player))
               return
            end
         end

         -- Create new generator with existing player
         local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"
         local generator = TunnelWorldGenerator(nil, player)
         local loadingState = spectrum.gamestates.LoadingState(generator, self.display, self.overlayDisplay, player)
         self.manager:enter(loadingState)
      else
         prism.logger.warn("No player found when descending, creating new level")
         local TunnelWorldGenerator = require "modules.game.world.tunnelworldgenerator"
         local generator = TunnelWorldGenerator()
         local loadingState = spectrum.gamestates.LoadingState(generator, self.display, self.overlayDisplay)
         self.manager:enter(loadingState)
      end
   end

   if (prism.messages.LoseMessage:is(message)) then
      Audio.playLose()
      local player = self.level:query(prism.components.PlayerController):first()
      self.manager:enter(spectrum.gamestates.DeathState(self.display, self.overlayDisplay, player))
   end

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
function PlayState:canUseAbility(player, activeItem, targetPosition, playSound)
   if not player or not activeItem or not targetPosition then
      return false
   end

   local direction = targetPosition - player:getPosition()
   local ability = prism.actions.ItemAbility(player, activeItem, direction)

   local costLegal, cooldownLegal = ability:canFire(self.level)
   local rangeLegal, seesLegal, pathsLegal, targetContainsPlayerIfNecessary = ability:canTarget(self.level)

   if playSound then
      if rangeLegal and seesLegal and pathsLegal and not costLegal then
         prism.logger.info("play click")
         Audio.playClick()
      end
   end

   return costLegal and cooldownLegal and rangeLegal and seesLegal and pathsLegal and targetContainsPlayerIfNecessary
end

-- updateDecision is called whenever there's an ActionDecision to handle.
function PlayState:updateDecision(dt, owner, decision)
   -- Controls need to be updated each frame.
   controls:update()

   local player = self.level:query(prism.components.PlayerController):first()

   if not player then return end

   local inventory = player:expect(prism.components.Inventory)
   local activeItem = player:expect(prism.components.Slots):activeItem()


   if controls.dash_mode.pressed or controls.dash_mode.down then
      self:trySetDashDestinationTiles(self.level, owner)

      if controls.dash_mode.pressed then
         Audio.playDashStart()
      end
   end

   if controls.dash_mode.released then
      self:clearAllDashDestinationTiles()
   end

   -- Controls are accessed directly via table index.
   if controls.move.pressed and not controls.dash_mode.down then
      -- Check if destination is occupied by an entity with Health
      local destination = owner:getPosition() + controls.move.vector
      local target = self.level:query(prism.components.Health):at(destination:decompose()):first()

      -- check for stairs in our destination
      local stairs = self.level:query(prism.components.Stair):at(destination:decompose()):first()

      if stairs then
         if self:setAction(prism.actions.Descend(owner, stairs)) then return end
      end

      if target and not target:has(prism.components.Item) then
         -- Check if player has a melee weapon
         local slots = player:expect(prism.components.Slots)
         local melee = slots:get(slots:getSlotsForType("Melee")[1])

         if melee then
            -- Perform melee attack instead of move
            local ability = prism.actions.ItemAbility(owner, melee, controls.move.vector)

            Audio.playCyclone()

            if self:setAction(ability) then
               return
            end
         end
      end

      -- If no melee attack, try normal move
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
            Audio.playDashEnd()
            self:clearAllDashDestinationTiles()
            return
         end
      end
   end

   if controls.reload.pressed then
      prism.logger.info("reload pressed")

      local reload = prism.actions.Reload(player, activeItem, false)
      local s, e = self:setAction(reload)
   end

   if controls.use.pressed then
      if self.mouseCellPosition and player and not controls.dash_mode.down and activeItem then
         self.firing = true

         prism.logger.info("active: ", activeItem:getName())

         if activeItem and self:canUseAbility(player, activeItem, self.mouseCellPosition, true) then
            local ranges = activeItem:expect(prism.components.Range)
            local pos = TEMPLATE.adjustPositionForRange(player, self.mouseCellPosition, ranges)

            local ability = prism.actions.ItemAbility(owner, activeItem, pos - owner:getPosition())

            local s, e = self:setAction(ability)
         end
      end
   end

   if controls.drop.pressed then
      if activeItem then
         prism.logger.info("DROPPING ITEM: ", activeItem:getName())
         local s, e = self:setAction(prism.actions.DropItem(owner, activeItem))
      end
   end

   -- Hold-to-confirm consume UI
   if controls.consume.down and activeItem then
      local playerComp = player:expect(prism.components.Player)
      playerComp.consumeHoldProgress = playerComp.consumeHoldProgress + dt

      -- Trigger consume action when held for 1 second
      if playerComp.consumeHoldProgress >= 1.0 then
         local s, e = self:setAction(prism.actions.Consume(owner, activeItem))
         playerComp.consumeHoldProgress = 0 -- Reset after consuming
      end
   else
      -- Reset timer when button is released or no active item
      if player:has(prism.components.Player) then
         player:expect(prism.components.Player).consumeHoldProgress = 0
      end
   end

   if controls.dismiss.pressed then
      local dialog = player:expect(prism.components.Dialog)

      dialog:pop()
   end

   if controls.wait.pressed then self:setAction(prism.actions.Wait(owner)) end

   local slots = player:expect(prism.components.Slots)

   for i = 1, 8 do
      if controls["slot" .. tostring(i)] and controls["slot" .. tostring(i)].pressed then
         slots:activate(i)
      end
   end
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

   local playerSenses = player:get(prism.components.Senses)

   if playerSenses and playerSenses.cells:get(self.mouseCellPosition:decompose()) then
      self.targetPanel.mouseOverActor = self.mouseOverActor
      self.targetPanel.mouseCellPosition = self.mouseCellPosition
   else
      self.targetPanel.mouseOverActor = nil
      self.targetPanel.mouseCellPosition = nil
   end

   local activeItem = player:expect(prism.components.Slots):activeItem()

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
      self.display:putBG(pos.x, pos.y, C.DASH_DESTINATION, math.huge)
   end

   -- Get player's senses to filter visible tiles
   local playerSenses = player:get(prism.components.Senses)


   -- Collect and sort actors so mouseOverActor is last
   local actorsWithControllers = {}
   for actor, controller in self.level:query(prism.components.Controller):iter() do
      table.insert(actorsWithControllers, { actor = actor, controller = controller })
   end
   table.sort(actorsWithControllers, function(a, b)
      if a.actor == self.mouseOverNPC then return false end
      if b.actor == self.mouseOverNPC then return true end
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
            -- both types implement this, don't worry
            local destinations = intent:getDestinations()

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
                  self.overlayDisplay:print(ox + 2, oy, "EMPTY", C.WARNING_FG,
                     C.WARNING_BG)
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

               local impacts = TEMPLATE.getAllImpactPositions(self.level, player, activeItem, pos)

               local cost = activeItem:get(prism.components.Cost)
               local multi = (cost and cost.multi) or 1

               local push = {}
               for _, impact in ipairs(impacts) do
                  local actor = self.level:query(prism.components.Collider):at(impact:decompose()):first()

                  if actor and canUse and playerSenses and playerSenses.cells:get(impact:decompose()) then
                     local vector = effect:getPushVector(actor, player, impact)
                     if not push[actor] then
                        push[actor] = { amount = 0, vector = vector }
                     end
                     push[actor].amount = push[actor].amount + (effect.push * multi)
                  end
               end

               for actor, data in pairs(push) do
                  local action = prism.actions.Push(player, actor, data.vector, data.amount, false)
                  local success = self.level:canPerform(action)

                  if success then
                     for i, result in ipairs(action.results) do
                        local last = i == action.steps
                        if not result.collision then
                           local char = actor:expect(prism.components.Drawable).index
                           local color = last and C.PUSH_VALID or C.PUSH_PATH
                           self.display:put(result.pos.x, result.pos.y, char, color, prism.Color4.TRANSPARENT)
                        else
                           self.display:put(result.pos.x, result.pos.y, "x", C.PUSH_COLLISION, prism.Color4.TRANSPARENT)
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

               local impacts = TEMPLATE.getAllImpactPositions(self.level, player, activeItem, pos)

               self.overlayDisplay:beginCamera()
               for _, impact in ipairs(impacts) do
                  -- the historical way of doing this.
                  -- which we choose is going to depend on the art style we end up with. this is ugly, but functional for the moment.˝
                  -- self:blendBG(impact.x, impact.y, C.ABILITY_IMPACT, self.display)

                  self.display:putFG(impact.x, impact.y, C.ABILITY_IMPACT, math.huge)
                  self.display:putBG(impact.x, impact.y, C.ABILITY_IMPACT, math.huge)
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
      self.overlayDisplay:rectangle("fill", 0, PANEL_Y - 1, SCREEN_WIDTH * 4 + 1, PANEL_HEIGHT, " ",
         prism.Color4.TRANSPARENT,
         prism.Color4.BLACK)

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
---@param playerSenses Senses
function PlayState:drawHealthBars(playerSenses)
   local damage = {}
   local push = {}

   local accumulate = function(pos, effect, owner)
      local actor = self.level:query(prism.components.Health):at(pos.x, pos.y):first()

      if actor and playerSenses.cells:get(pos:decompose()) and actor ~= owner then
         damage[actor] = (damage[actor] or 0) + effect.health

         if effect.push and effect.push > 0 then
            local vector = effect:getPushVector(actor, owner, pos)
            if not push[actor] then
               push[actor] = { amount = 0, vector = vector, owner = owner }
            end
            push[actor].amount = push[actor].amount + effect.push
         end
      end
   end

   local applyPushDamage = function()
      for actor, data in pairs(push) do
         local action = prism.actions.Push(data.owner, actor, data.vector, data.amount, false)
         self.level:canPerform(action)

         if action.collision then
            damage[actor] = (damage[actor] or 0) + COLLISION_DAMAGE
         end
      end
   end


   -- TODO this whole section is repetitive of the Ability action. Need to consolidate the logic significantly between the two.
   local player = self.level:query(prism.components.PlayerController):first()
   if not player then return end

   local activeItem = player:expect(prism.components.Slots):activeItem()

   if activeItem then
      local effect = activeItem:expect(prism.components.Effect)
      local cost = activeItem:get(prism.components.Cost)

      if effect.health or effect.push then
         if self:canUseAbility(player, activeItem, self.mouseCellPosition) then
            local multi = (cost and cost.multi) or 1
            local impacts = TEMPLATE.getAllImpactPositions(self.level, player, activeItem, self.mouseCellPosition)

            for shot = 1, multi do
               for _, pos in ipairs(impacts) do
                  accumulate(pos, effect, player)
               end
            end

            applyPushDamage()
         end
      end
   end

   for actor, controller in self.level:query(prism.components.BehaviorController):iter() do
      ---@cast controller BehaviorController
      if controller.intent and prism.actions.ItemAbility:is(controller.intent) then
         local action = controller.intent
         ---@cast action ItemAbility
         local item = action:getItem()
         local effect = item:expect(prism.components.Effect)

         if effect.health then
            local target = action:getTargeted(2) + actor:getPosition()
            local impacts = TEMPLATE.getAllImpactPositions(self.level, actor, item, target)

            for _, pos in ipairs(impacts) do
               accumulate(pos, effect, actor)
            end
         end
      end
   end

   applyPushDamage()

   -- reduce for armor
   local adjustedDamage = {}
   for actor, dmg in pairs(damage) do
      local armor = actor:get(prism.components.Armor)

      if armor then
         adjustedDamage[actor] = math.max(dmg - armor.strength, 0)
      else
         adjustedDamage[actor] = dmg
      end
   end

   damage = adjustedDamage

   self.overlayDisplay:beginCamera()
   for actor, dmg in pairs(damage) do
      if actor then
         local health = actor:expect(prism.components.Health)
         local armor = actor:get(prism.components.Armor)
         local armorStrength = armor and armor.strength or 0
         local pos = actor:getPosition()
         local tx = (pos.x - 1) * 4
         local ty = pos.y * 2
         local tiles = helpers.calculateHealthBarTiles(health.value, health.value - dmg, armorStrength)

         for i, tile in ipairs(tiles) do
            self.overlayDisplay:put(tx + i, ty, tile.index, tile.fg, tile.bg, math.huge)
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
      self.mouseOverNPC = self.level:query(prism.components.BehaviorController):at(self.mouseCellPosition:decompose())
          :first()

      self.mouseOverActor = self.level:query():at(self.mouseCellPosition:decompose()):first()
   end
end

function PlayState:highlightIntent(actor)
   if self.mouseOverNPC then
      return self.mouseOverNPC == actor
   else
      return true
   end
end

function PlayState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.SensesSystem):postInitialize(self.level)
end

return PlayState
