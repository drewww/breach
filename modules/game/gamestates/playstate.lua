local controls = require "controls"
local helpers = require "util.helpers"


--- @class PlayState : OverlayLevelState
--- A custom game level state responsible for initializing the level map,
--- handling input, and drawing the state to the screen.
---
--- @overload fun(display: Display, overlayDisplay: Display): PlayState
local PlayState = spectrum.gamestates.OverlayLevelState:extend "PlayState"

--- @param display Display
--- @param overlayDisplay Display
function PlayState:__new(display, overlayDisplay)
   -- Construct a simple test map using MapBuilder.
   -- In a complete game, you'd likely extract this logic to a separate module
   -- and pass in an existing player object between levels.
   local builder = prism.LevelBuilder()

   builder:rectangle("line", 0, 0, 32, 32, prism.cells.Wall)
   -- Fill the interior with floor tiles
   builder:rectangle("fill", 1, 1, 31, 31, prism.cells.Floor)
   -- Add a small block of walls within the map
   builder:rectangle("fill", 5, 5, 7, 7, prism.cells.Wall)
   -- Add a pit area to the southeast
   builder:rectangle("fill", 20, 20, 25, 25, prism.cells.Pit)

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 12, 12)

   -- Add systems
   builder:addSystems(prism.systems.SensesSystem(), prism.systems.SightSystem(), prism.systems.ExpiringSystem(),
      prism.systems.DiffusionSystem())

   builder:addTurnHandler(prism.turnhandlers.IntenfulTurnHandler())

   --- @field Vector2[]
   self.dashDestinationLocations = {}

   --- @type Vector2?
   self.mouseCellPosition = nil
   self.mouseCellPositionChanged = false
   self.firing = false
   self.lastTargetCount = 0

   -- key: actor, value: Animation[]
   self.actorAnimations = {}

   -- Initialize with the created level and display, the heavy lifting is done by
   -- the parent class.
   self.super.__new(self, builder:build(prism.cells.Wall), display, overlayDisplay)

   self.super.addPanel(self, HealthPanel(overlayDisplay, prism.Vector2(0, 0)))
   self.super.addPanel(self, ItemPanel(overlayDisplay, prism.Vector2(0, 2)))

   local weapons = {}
   table.insert(weapons, prism.actors.Shotgun())
   table.insert(weapons, prism.actors.Pistol())
   table.insert(weapons, prism.actors.Laser())
   table.insert(weapons, prism.actors.Grenade(3))
   table.insert(weapons, prism.actors.SmokeGrenade(3))


   for i, weapon in ipairs(weapons) do
      if i == 1 then
         weapon:give(prism.components.Active())
      end

      player:expect(prism.components.Inventory):addItem(weapon)
   end

   player:expect(prism.components.Inventory):addItem(AMMO_TYPES["Pistol"](50))
end

function PlayState:handleMessage(message)
   -- prism.logger.info("handling message: ", message)

   self.super.handleMessage(self, message)

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
      local move = prism.actions.Move(owner, controls.move.vector, true)

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

      local reload = prism.actions.Reload(player, item)
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
      if self.mouseCellPosition and player then
         self.firing = true
         local activeItem = player:expect(prism.components.Inventory):query(prism.components.Ability,
            prism.components.Active):first()

         if activeItem then
            local ranges = activeItem:expect(prism.components.Range)
            local pos = prism.components.Template.adjustPositionForRange(player, self.mouseCellPosition, ranges)

            local ability = prism.actions.ItemAbility(owner, activeItem, pos - owner:getPosition())

            local s, e = self:setAction(ability)
            prism.logger.info("ability: ", s, e)
         end
      end
   end

   if controls.wait.pressed then self:setAction(prism.actions.Wait(owner)) end
end

function PlayState:draw()
   self.display:clear()
   self.overlayDisplay:clear()

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

   for actor, controller in self.level:query(prism.components.Controller):iter() do
      ---@cast controller Controller
      ---@cast controller +IIntentful
      local intent = controller.intent
      if intent then
         if prism.actions.Fly:is(intent) then
            ---@cast intent Fly
            for _, pos in ipairs(intent:getDestinations()) do
               self.display:putBG(pos.x, pos.y, prism.Color4.GREEN, 100)
            end
         end

         if prism.actions.Move:is(intent) then
            ---@cast intent Move
            local destination = intent:getDestination()
            self.display:putBG(destination.x, destination.y, prism.Color4.GREEN, 100)
         end

         if prism.actions.ItemAbility:is(intent) then
            ---@cast intent ItemAbility

            local targets = intent:getTargetedCells()
            for _, pos in ipairs(targets) do
               self.display:putBG(pos.x, pos.y, prism.Color4.RED:lerp(prism.Color4.BLACK, 0.6), 100)
            end
         end
      end
   end

   local activeItems = player:expect(prism.components.Inventory):query(prism.components.Ability,
      prism.components.Active)
   local activeItem = activeItems:first()

   if self.mouseCellPosition then
      if player then
         -- visualize push effects
         if activeItem then
            local effect = activeItem:expect(prism.components.Effect)

            local template = activeItem:expect(prism.components.Template)
            if effect.push > 0 then
               local ranges = activeItem:get(prism.components.Range)
               local pos = self.mouseCellPosition:copy()
               if ranges then
                  pos = prism.components.Template.adjustPositionForRange(player, pos, ranges)
               end

               local targets = prism.components.Template.generate(template, player:getPosition(), pos)

               for _, target in ipairs(targets) do
                  local actor = self.level:query(prism.components.Collider):at(target:decompose()):first()
                  if actor then
                     local vector = actor:getPosition() - player:getPosition()

                     if effect.pushFromCenter then
                        vector = actor:getPosition() - pos
                     end

                     -- route through the action target rules to confirm that this is legal. Though we will not actually use this action for anything.
                     local success, err = self.level:canPerform(prism.actions.Push(player, actor, vector, effect.push))

                     if success then
                        -- visualize the push
                        local pushResult, totalSteps = RULES.pushResult(self.level, actor, vector, effect.push)

                        for index, result in ipairs(pushResult) do
                           local lastStep = index == totalSteps

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
      end

      -- visualize target area
      if player and not self.firing then
         if activeItem then
            local template = activeItem:expect(prism.components.Template)
            local ranges = activeItem:get(prism.components.Range)
            local pos = self.mouseCellPosition:copy()

            if ranges then
               pos = prism.components.Template.adjustPositionForRange(player, pos, ranges)
            end

            local targets = prism.components.Template.generate(template, player:getPosition(), pos)

            self.overlayDisplay:beginCamera()
            for _, target in ipairs(targets) do
               self.display:putBG(target.x, target.y, prism.Color4.BLUE:lerp(prism.Color4.BLACK, 0.2), 100)
            end
            self.overlayDisplay:endCamera()
         end
      end

      self:drawHealthBars()

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

      -- prism.logger.info("panels: ", #self.panels)
      self.super.putPanels(self)

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

function PlayState:drawHealthBars()
   -- for now it's an integer summing up damage, later can expand to other effects
   local actorsReceivingEffects = {}

   local processEffectOnCells = function(targets, damage)
      for _, target in ipairs(targets) do
         local actor = self.level:query(prism.components.Health):at(target.x, target.y):first()
         if actor then
            if not actorsReceivingEffects[actor] then
               actorsReceivingEffects[actor] = 0
            end

            actorsReceivingEffects[actor] = actorsReceivingEffects[actor] + damage
         end
      end
   end

   -- HANDLE ACTIVE PLAYER ITEM DAMAGE
   local player = self.level:query(prism.components.PlayerController):first()

   if not player then return end

   local activeItem = player:expect(prism.components.Inventory):query(prism.components.Ability,
      prism.components.Active):first()

   if activeItem then
      local template = activeItem:expect(prism.components.Template)

      local targets = prism.components.Template.generate(template, player:getPosition(), self.mouseCellPosition)

      local effect = activeItem:expect(prism.components.Effect)
      -- add the template targeted actors

      if effect.health then
         processEffectOnCells(targets, effect.health)
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
               local targets = action:getTargetedCells()
               processEffectOnCells(targets, effect.health)
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
            local ty = (target.y - 1) * 2

            local tiles = helpers.calculateHealthBarTiles(healthValue, postDamageHealth)

            for i, tile in ipairs(tiles) do
               prism.logger.info("health tile: ", i, tile.fg, tile.bg)
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
   end
end

function PlayState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.SensesSystem):postInitialize(self.level)
end

return PlayState
