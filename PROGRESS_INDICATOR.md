# Progress Indicator System for World Generation

This document describes the progress indicator system implemented for the TunnelWorldGenerator.

## Overview

The progress indicator provides real-time feedback to players during procedural world generation. Instead of a blank screen or frozen game, players see:
- A progress bar showing completion percentage
- Current generation phase (e.g., "Tunneling (5-wide): 120/300")
- Step counter showing progress through estimated total steps

## Architecture

The system consists of three main components:

### 1. TunnelWorldGenerator (Progress Tracking)

**File:** `modules/game/world/tunnelworldgenerator.lua`

The generator tracks its progress through several fields added to the constructor:

```lua
-- Progress tracking fields
self.estimatedRoomSteps = 100
self.estimatedFillerSteps = 50
self.estimatedTotalSteps = self.maxSteps5Wide + self.maxSteps3Wide + 
    self.estimatedRoomSteps + self.estimatedFillerSteps
self.currentStep = 0
self.progressPhase = "Initializing"
```

**Progress Phases:**
1. **5-wide tunneling** - Main corridor generation
2. **3-wide tunneling** - Secondary hallway pass
3. **Room generation** - Creating rooms in empty spaces
4. **Room filling** - Adding furniture and objects to rooms
5. **Junction filling** - Adding pillars and decorations to junctions

**Key Method:**
```lua
function TunnelWorldGenerator:getProgress()
    return {
        phase = self.progressPhase,
        current = self.currentStep,
        total = self.estimatedTotalSteps,
        percentage = math.floor((self.currentStep / self.estimatedTotalSteps) * 100)
    }
end
```

Each `coroutine.yield()` in the generation process increments `currentStep` and updates `progressPhase` with a descriptive message.

### 2. LoadingState (Display Layer)

**File:** `modules/game/gamestates/loadingstate.lua`

A new game state that:
- Runs the generation coroutine frame-by-frame
- Displays a visual progress indicator
- Automatically transitions to PlayState when complete

**Features:**
- Centered title: "GENERATING FACILITY"
- ASCII progress bar using `─` and `█` characters
- Percentage display
- Current phase description
- Step counter (current/total)
- ESC key to cancel generation (returns to previous state)

**Visual Layout:**
```
        GENERATING FACILITY
    ████████████████────────────────
              40%
    Tunneling (5-wide): 120/300
          120 / 470 steps
```

**Update Loop:**
The `update()` method resumes the generation coroutine each frame:
```lua
function LoadingState:update(dt)
    local success, result = coroutine.resume(self.generationCoroutine)
    
    if coroutine.status(self.generationCoroutine) == "dead" then
        -- Generation complete - transition to PlayState
        local PlayState = require "modules.game.gamestates.playstate"
        local playState = PlayState(self.display, self.overlayDisplay, self.builder)
        self:getManager():push(playState)
    end
end
```

**Important:** PlayState is lazy-loaded (required inside the method, not at file level) to avoid circular dependency issues during module loading.

### 3. TitleState Integration

**File:** `modules/game/gamestates/titlestate.lua`

The title screen menu now creates a LoadingState when the player selects "play":

```lua
if option.state == "PlayState" then
    local generator = TunnelWorldGenerator()
    local loadingState = spectrum.gamestates.LoadingState(generator, self.display, self.overlayDisplay)
    self:getManager():push(loadingState)
end
```

## Technical Details

### Coroutine System

The generator uses Lua coroutines to yield control back to the game loop:

1. **Generator yields** - After each generation step, `coroutine.yield()` is called
2. **LoadingState resumes** - Each frame, the coroutine is resumed
3. **UI updates** - Progress info is read and displayed
4. **Completion** - When the coroutine status becomes "dead", transition to PlayState

This approach allows:
- Non-blocking generation (game doesn't freeze)
- Real-time progress updates
- Smooth frame rate during generation
- Ability to cancel generation (ESC key)

### Progress Estimation

The total step count is estimated based on:
- **5-wide pass**: Actual budget (`maxSteps5Wide`)
- **3-wide pass**: Actual budget (`maxSteps3Wide`)
- **Rooms**: Fixed estimate (~100 steps)
- **Fillers**: Fixed estimate (~50 steps)

The estimates for rooms and fillers are rough but provide reasonable accuracy. The actual number of steps may vary, but the percentage gives a good indication of overall progress.

### Module Loading Order

**Important:** To avoid circular dependencies:
1. LoadingState extends `spectrum.GameState` directly (no top-level requires)
2. PlayState is lazy-loaded inside `LoadingState:update()` only when needed
3. TitleState references LoadingState through `spectrum.gamestates` registry

This ensures all modules load correctly without dependency issues.

## Customization

### Adjusting Progress Estimates

To adjust step estimates, modify the constructor in `tunnelworldgenerator.lua`:

```lua
self.estimatedRoomSteps = 100  -- Increase if room generation takes longer
self.estimatedFillerSteps = 50 -- Increase if filler pass is slow
```

### Changing Visual Style

Modify `LoadingState:draw()` to customize:
- Progress bar characters (currently `─` and `█`)
- Colors (currently WHITE, CYAN, GRAY, DARKGRAY)
- Layout and positioning
- Additional information displayed

### Adding More Detail

To add more granular progress tracking:
1. Add more `coroutine.yield()` calls in the generator
2. Update `progressPhase` with more detailed messages
3. Consider adding sub-phase tracking (e.g., "Room 5/12")

## Performance Considerations

- Each yield/resume cycle takes ~1 frame
- Generation with ~500 total steps = ~8 seconds at 60 FPS
- No significant performance overhead from progress tracking
- The UI rendering is lightweight (text only)

## Future Enhancements

Potential improvements:
1. **Preview rendering** - Show the map being generated in real-time
2. **Animation effects** - Pulse or animate the progress bar
3. **Phase icons** - Visual indicators for each generation phase
4. **Time estimation** - "~5 seconds remaining" based on current speed
5. **Cancellation confirmation** - Dialog before actually canceling generation
6. **Save/Load** - Allow saving generated maps for later use

## Troubleshooting

### Progress stuck at 100%?
Check if `coroutine.status()` is returning "dead". If not, there may be an infinite loop in the generator.

### Progress jumps erratically?
The room/filler estimates may be inaccurate. Adjust `estimatedRoomSteps` and `estimatedFillerSteps` to better match actual generation.

### "OverlayLevelState is nil" error?
This indicates a module loading order issue. Ensure PlayState is lazy-loaded in LoadingState, not required at the file's top level.

### No progress display?
Verify `SCREEN_WIDTH` and `SCREEN_HEIGHT` constants are defined in `util/constants.lua`.