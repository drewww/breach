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

   self.startDestinationsVisited = 0
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
      self:setRandomTrigger()
   elseif step == "melee" then
      -- do entering-step action
   end
end

function TutorialSystem:onMove(level, actor, from, to)
   local cellMovedInto = self.level:getCell(to:decompose())

   if self.step == "start" then
      if cellMovedInto:has(prism.components.Trigger) then
         self.startDestinationsVisited = self.startDestinationsVisited + 1

         self:unhighlightCell(to:decompose())
         if self.startDestinationsVisited > 3 then
            prism.logger.info("TRANSITION TO NEXT MODE")
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
   local function valid(x, y)
      local player = self.level:query(prism.components.PlayerController):first()

      if not player then return false end

      local inBounds, notOnPlayer = self.level:inBounds(x, y),
          player and player:getPosition():getRange(prism.Vector2(x, y)) ~= 0

      local passable = false
      if inBounds then
         passable = self.level:getCellPassable(x, y, player:expect(prism.components.Mover).mask)
      end
      prism.logger.info("checking: ", x, y, inBounds, notOnPlayer)
      return inBounds and notOnPlayer and passable
   end

   local x, y = -1, -1

   while not valid(x, y) do
      -- this is stupid, but I can't seem to extract size of level easily
      x, y = math.random(1, 30), math.random(1, 30)
   end

   prism.logger.info("random: ", x, y)
   self:setNewTrigger(x, y)
end

return TutorialSystem
