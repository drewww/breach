--- @class TutorialState : PlayState
--- @field step string a string holding one of the various tutorial steps.

local TutorialState = spectrum.gamestates.PlayState:extend "TutorialState"

-- TODO some data structure that holds a list of valid steps.

--- @param display Display
--- @param overlayDisplay Display
function TutorialState:__new(display, overlayDisplay, step)
   prism.logger.info("CONSTRUCT TUTORIAL STATE")
   self.step = "start"

   local map = "start"
   local builder = prism.LevelBuilder.fromLz4("modules/game/world/prefab/tutorial/" .. map .. ".lvl")

   self.tutorialSystem = prism.systems.TutorialSystem()
   builder:addSystems(self.tutorialSystem)

   -- Place the player character at a starting location
   local player = prism.actors.Player()
   builder:addActor(player, 3, 3)

   self.super.__new(self, display, overlayDisplay, builder)

   self.tutorialSystem:init(self.level, self)
end

return TutorialState
