local controls = require "controls"

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

   --- @field Vector2[]
   self.dashDestinationLocations = {}

   --- @type Vector2?
   self.mouseCellPosition = nil
   self.mouseCellPositionChanged = false
   self.firing = false


   -- Initialize with the created level and display, the heavy lifting is done by
   -- the parent class.
   self.super.__new(self, builder:build(prism.cells.Wall), display, overlayDisplay)

   self.super.addPanel(self, HealthPanel(overlayDisplay, prism.Vector2(0, 0)))
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

   if controls.shoot.pressed then
      if self.mouseCellPosition then
         local target = self.level:query(prism.components.Health):at(self.mouseCellPosition:decompose()):first()

         local player = self.level:query(prism.components.PlayerController):first()

         -- switch to this for basic shot
         -- local shoot = prism.actions.Shoot(player, target, 1, 2)

         if player then
            self.firing = true
            local vector = self.mouseCellPosition - player:getPosition()
            local angle = math.atan2(vector.y, vector.x)
            local bounceShoot = prism.actions.BounceShoot(player, math.atan2(vector.y, vector.x), 20)
            prism.logger.info("attempting to bounce shoot: ", vector)
            local s, e = self:setAction(bounceShoot)
            prism.logger.info("bounceshot: ", s, e, angle)
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
   else
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
   end

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
               self.display:putBG(pos.x, pos.y, prism.Color4.GREEN, math.huge)
            end
         end

         if prism.actions.Move:is(intent) then
            ---@cast intent Move
            local destination = intent:getDestination()
            self.display:putBG(destination.x, destination.y, prism.Color4.GREEN, math.huge)
         end
      end
   end

   if self.mouseCellPosition then
      local actor = self.level:query(prism.components.Collider):at(self.mouseCellPosition:decompose()):first()

      if actor and player then
         local vector = actor:getPosition() - player:getPosition()

         -- route through the action target rules to confirm that this is legal. Though we will not actually use this action for anything.
         local success, err = self.level:canPerform(prism.actions.Push(player, actor, vector, 3))

         if success then
            -- visualize the push
            local pushResult, totalSteps = RULES.pushResult(self.level, actor, vector, 2)

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
                  self.display:put(result.pos.x, result.pos.y, "x", prism.Color4.RED, prism.Color4.TRANSPARENT)
               end
            end
         end
      end

      if player and not self.firing then
         local vector = self.mouseCellPosition - player:getPosition()
         local bounces = RULES.bounce(self.level, player:getPosition(), 20, math.atan2(vector.y, vector.x))

         local playerSense = player:expect(prism.components.Senses)

         for i, bounce in ipairs(bounces) do
            local cell = self.level:getCell(bounce.pos.x, bounce.pos.y)

            -- local seenByPlayer = self.level:getCell(bounce.pos.x, bounce.pos.y):hasRelation(
            -- prism.relations.SensedByRelation, player)

            local seenByPlayer = playerSense.cells:get(bounce.pos.x, bounce.pos.y)

            if seenByPlayer then
               self.display:putBG(bounce.pos.x, bounce.pos.y, prism.Color4.BLACK:lerp(prism.Color4.YELLOW, i / 20),
                  math.huge)
            else
               break
            end
         end
      end
   end
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

function PlayState:mousemoved()
   local cellX, cellY, targetCell = self:getCellUnderMouse()
   self.mouseCellPosition = prism.Vector2(cellX, cellY)
   self.firing = false
end

function PlayState:resume()
   -- Run senses when we resume from e.g. Geometer.
   self.level:getSystem(prism.systems.SensesSystem):postInitialize(self.level)
end

return PlayState
