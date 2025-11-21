require "debugger"
require "prism"

require "util.constants"

prism.loadModule("prism/spectrum")
prism.loadModule("prism/geometer")
prism.loadModule("prism/extra/sight")
prism.loadModule("modules/game")

-- Used by Geometer for new maps
prism.defaultCell = prism.cells.Floor

-- Load a sprite atlas and configure the terminal-style display,
love.graphics.setDefaultFilter("nearest", "nearest")

local macroAtlas = spectrum.SpriteAtlas.fromASCIIGrid("display/spritesheets/cp437_32x32.png", 32, 32)
local microAtlas = spectrum.SpriteAtlas.fromASCIIGrid("display/spritesheets/wanderlust_16x16.png", 16, 16)

local macroDisplay = spectrum.Display(SCREEN_WIDTH, SCREEN_HEIGHT, macroAtlas, prism.Vector2(32, 32))
local microDisplay = spectrum.Display(SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2, microAtlas, prism.Vector2(16, 16))

-- Automatically size the window to match the terminal dimensions
-- Should not matter which we use for this, since they are the same pixel dimensions.
macroDisplay:fitWindowToTerminal()

-- spin up our state machine
--- @type GameStateManager
local manager = spectrum.StateManager()

-- we put out levelstate on top here, but you could create a main menu
--- @diagnostic disable-next-line
function love.load()
   manager:push(spectrum.gamestates.PlayState(macroDisplay))
   manager:hook()
   spectrum.Input:hook()
end
