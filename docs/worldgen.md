WORLD GENERATION
================

We're building a tunnel based world generation system. 

It's inspired by this blogpost: https://www.gridsagegames.com/blog/2014/06/mapgen-tunneling-algorithm/

First let's describe how we want the outcomes to feel:
   - Hallways are mostly straight, but sometimes turn.
   - Most of the space of a floor is in rooms or wide-open spaces, the rest is hallways. 
   - Hallways have 3 sizes -- 1 wide, 3 wide, and 5 wide. Think of this like highways, main roads, and side roads.
   - Hallways should not turn back on themselves often; after a turn they should run straight for a while.
   - Hallways should occasionally create varying sized junctions: a junction that is at minimum one width bigger than the hallway, at maximum 8 steps bigger than the hallway. Most of the time this is simply 1 or 2 steps bigger. 
      - When this happens, the hallway should END and then we should consider create new hallways from the edges of this junction, but they need not be aligned with the center of the junction.
   - if a hallway is approaching (i.e. within the next 3 steps) an already-opened up space, either: merge (and end the agent), turn away from it (if a turn is valid; it needs to have been enough steps since the last turn, and there needs to be enough "open" space in the direction we're turning to continue for a minimum distance), or simply terminate in a dead-end. 


Some parameters we'll need to include:
 - minimum distances until a choice -- we should not add features rapidly. if we've turned, go straight for a while. if we've made a junction and continued through it, don't make another immediately. 
 - open space. we need a standard way to look both "ahead" to see if it's clear, and to either side of a turn, to see if that turn is going to be valid.
 - I like using string-based options selectors, i.e. a list like "{"junction-continue", "junction-end", "junction-turn-left"}" to enumerate the options, and then we can adjust the odds by making options repeat. Or remove options if they fail the test. So like start with a full list of options, then prune the ones that are not valid in this situation.
 - we need some guidance on how much of each type of hallway or junction to make. so like at the start of a run, randomize parameters like "number of junctions" and max length of large, medium, and small hallways. So we don't just count on step-wise odds to terminate hallways.

TODO we have no logic for placing rooms yet. I think that happens in a second pass.

TODO we have no description yet of how to make smaller paths. for now, let's assume that happens in secondary passes. we do one pass for big hallways, then another pass starting from open spaces on the big hallways to make mediums, then place rooms(?) and then add in mini one-wide hallways connecting.

Rough pseudocode:
 - spawn some number of initial agents doing big hallways
 - iterate forward until we have gone a minimum distance between-features. the odds of a feature increase the more steps it's been since we've been eligible for a feature without having one. then decide if we want a feature: junction, turn, stop (if we're near the max). run this as a bag of options that are prepopulated at the start and once used, are consumed. so we have a fixed number of each of these. 
   - junctions can be straight, turn, 3-way, or 4-way. 3-way adds an agent going perpandeicularly to the current agent, 4-way adds two agents going both directions away.
   - turn-left and turn-right options must be valid to be included in the list.
 - if we're iterating and we're about to hit another hallway, consider a list of options again: merge (break the walls between here and there and end this agent), continue (rare option, break through but don't end this agent), terminate, or turn (only include these options if that turn is valid and it's been sufficient distance for another feature)
- iterate until we hit a limit on hallways. if we're way below the target length of wide hallways, add another wide hallway tunneler at an open start away from occupied areas.
- repeat for 3-wide hallways, starting multiple tunnelers from places on hallways where there is "space", i.e. no features nearby on that hallway and it's going straight. 
   - 3-wide hallways are not eligible for features, and have much more limited disdtances. they are very likely to merge, and somewhat likely to turn if possible.


FAQ - ANSWER THESE BEFORE IMPLEMENTING
========================================

## Algorithm Initialization

**Q: How does generation start? Where do we place the first agent(s)?**
A: Pick a random spot on the edge, pointing in.

**Q: How many initial agents for 5-wide hallways? How are they positioned?**
A: Let's start with 1.

**Q: What's the map size?**
A: 100x100 to start.

**Q: What are the termination conditions? When does the algorithm stop?**
A: Set a max number of large hallway steps. As we get closer to that number, the odds of terminating any active 5-wide hallway increases each step until it's 100% odds of ending all active. Same for 3-wide.

## Hallway Mechanics

**Q: What's the minimum straight distance after a turn before the agent can turn again?**
A: Let's say ... 8 steps.

**Q: What's the minimum clear space needed to execute a turn (checking perpendicular to current direction)?**
A: 8 steps clear in that direction.

**Q: Can hallways only turn 90 degrees, or are other angles possible?**
A: Only 90 degrees.

**Q: What's the typical straight segment length range for 5-wide hallways?**
A: Maybe 15? 

**Q: What's the typical straight segment length range for 3-wide hallways?**
A: Not sure let's come back to it.

## Junction Mechanics

**Q: Junction sizing - "1 to 8 steps bigger than hallway" - does this mean a 5-wide hallway creates a junction that's 6x6 to 13x13? Or is it added to just one dimension?**
A: yes, 6x6 to 13x13.

**Q: What shape are junctions? Square? Rectangular? If rectangular, what proportions?**
A: Rectangular, allow width and height to randomize, with a heavy weight towards the smaller ends.

**Q: When a junction spawns new hallways, how do we decide how many and where? (e.g., straight junction = 1 exit, 3-way = 2 exits, 4-way = 3 exits?)**
A: When a junction spawns them, yes, have them aligned with the center and as you describe that number of exits. Smaller hallways can emerge from unused sides of junctions, though.

**Q: When new hallways spawn from a junction, do they maintain the same width or can they be narrower?**
A: Keep the same width for now, handle different width hallways in secondary passes.

## Rooms

**Q: How are rooms different from junctions? Size? Shape? Placement rules?**
A: Rooms sit on either side of hallways, with doors into the hallway. But place them AFTER we place all the major hallways.

**Q: What's the target ratio of room-space to hallway-space on a floor?**
A: 60/30/10, room, hallway, unused.

**Q: How do rooms connect to the hallway system?**
A: spawn off hallways. 

## Collision & Spacing

**Q: When checking if we're "about to hit another hallway", what's the lookahead distance? Still 3 steps?**
A: Try 5? It should be enough that if you turn there's at least a one width wall between you and the thing you're avoiding.

**Q: What's the minimum spacing between parallel hallways?**
A: 1 is fine.

**Q: Are dead-ends acceptable or should we try to minimize them?**
A: Dead-ends fine.

## Probabilities & Distributions

**Q: For 5-wide hallways, what's the baseline probability distribution for features when eligible? (e.g., 60% continue, 20% junction, 10% turn, 10% stop?)**
A: 95% continue, 5% feature. when a feature hits, there's a basket of options generated up front for that agent of turns and junction-types. Use those up over time.

**Q: How much should feature probability increase per step after becoming eligible?**
A: Start at 2%, increase to 100% over 4*minimum distance steps.

**Q: For junction size, what's the distribution? (e.g., 70% +1-2, 20% +3-5, 10% +6-8?)**
A: yes, that.

**Q: For 3-wide hallways, what are the merge vs turn vs terminate probabilities?**
A: 

## Resource Budgets

**Q: What are the initial random ranges for "number of junctions" and "max length of large/medium/small hallways"?**
A: Let's say a range of 2-10 junctions, 1-10 turns (randomly left/right). 

Max length of hallways, no idea. Set a reasonable default and we'll tune.

**Q: How do we know when we're "way below the target length" and need to spawn another tunneler?**
A: If all agents are dead and we're within 20% of the target, we're done. Otherwise make another agent in an open area.


IMPLEMENTATION PLAN
===================

## Phase 0: Preserve Existing Code (5 minutes)

**Goal:** Move current implementation out of the way without breaking anything.

1. Rename `breach/modules/game/world/tunneler.lua` → `breach/modules/game/world/legacytunneler.lua`
2. Rename `breach/modules/game/world/tunnelworldgenerator.lua` → `breach/modules/game/world/legacytunnelworldgenerator.lua`
3. Update `z_mapstate.lua` to reference `legacytunnelworldgenerator` temporarily
4. Test that the game still runs with legacy implementation

**Verification:** Game loads and generates a map using the old system.

---

## Phase 1: Core Infrastructure (30-45 minutes)

**Goal:** Set up the basic data structures and map builder without any actual generation logic.

### 1.1: Create TunnelAgent class
File: `breach/modules/game/world/tunnelagent.lua`

**What it contains:**
- Basic properties: position, direction, width, stepsSinceLastFeature, stepsSinceLastTurn, alive
- Budget tracking: availableJunctions (by type), availableTurns (left/right count)
- Constructor that takes position, direction, width, and generates random budgets (2-10 junctions, 1-10 turns)
- Empty methods to fill in later: `step()`, `dig()`, `checkCollision()`, `evaluateOptions()`
- Budget methods: `hasJunction()`, `consumeJunction(type)`, `hasTurn(direction)`, `consumeTurn(direction)`

**Why this first:** We need the agent structure before we can do anything else. Budget tracking lives here to keep state together.

### 1.2: Create TunnelWorldGenerator skeleton
File: `breach/modules/game/world/tunnelworldgenerator.lua`

**What it contains:**
- Basic setup: map size (100x100), LevelBuilder
- Empty `generate()` method with a placeholder loop
- Empty helper methods: `spawnAgent()`, `findOpenEdgeSpot()`, `stepAllAgents()`
- Just returns a filled rectangle for now

**Why this first:** We need the generator structure to tie everything together, but we're not implementing logic yet.

### 1.3: Hook up to game
File: `breach/modules/game/gamestates/z_mapstate.lua`

**What to do:**
- Update require to point to new `tunnelworldgenerator` (not legacy)
- Verify it loads

**Verification:** Game runs, generates a solid wall rectangle (no tunnels yet).

---

## Phase 2: Basic Single-Agent Tunneling (45-60 minutes)

**Goal:** Get one agent boring a straight hallway across the map.

### 2.1: Implement TunnelAgent:dig()
**What it does:**
- Calculate perpendicular vector
- Draw a line of Floor cells with the appropriate width
- Update position forward by 1

**Verification:** Agent leaves a trail of floor tiles.

### 2.2: Implement TunnelAgent:step() - Basic version
**What it does:**
- Call `dig()`
- Move position forward
- Check bounds (kill agent if out of bounds)
- Return alive status

**Verification:** Agent digs a straight line until it hits the edge and dies.

### 2.3: Implement TunnelWorldGenerator:generate() - Phase 2 version
**What it does:**
- Fill map with walls
- Spawn one agent at a random edge position pointing inward
- Loop while agents exist: step each agent, remove dead ones
- Yield after each step for visualization
- Return the built level

**Verification:** Watch a single 5-wide hallway bore straight across the map.

---

## Phase 3: Collision Detection (30-45 minutes)

**Goal:** Make agents detect when they're approaching existing tunnels.

### 3.1: Implement TunnelAgent:checkAhead()
**What it does:**
- Look ahead 5 steps in current direction
- Check a rectangle of width x 5 for any Floor cells
- Return true if clear, false if collision detected

**Why now:** This is needed before we can implement turn logic.

### 3.2: Update TunnelAgent:step() to handle collisions
**What it does:**
- Before digging, call `checkAhead()`
- If collision detected, kill the agent for now (we'll add options later)

**Verification:** Agent stops when approaching the edge, leaving a gap.

---

## Phase 4: Turning (45-60 minutes)

**Goal:** Make agents capable of turning 90 degrees.

### 4.1: Implement TunnelAgent:canTurn(direction)
**What it does:**
- Check if it's been at least 8 steps since last turn
- Look perpendicular in the specified direction (left or right)
- Check if there's at least 8 clear steps in that direction
- Return true/false

### 4.2: Implement TunnelAgent:executeTurn(direction)
**What it does:**
- Rotate direction vector 90 degrees (left = counterclockwise, right = clockwise)
- Reset stepsSinceLastTurn to 0
- Update agent state

### 4.3: Update TunnelAgent:step() with turn option
**What it does:**
- When collision detected, check if left turn is valid, check if right turn is valid
- Pick randomly from valid options (including terminate)
- If turn chosen, execute it
- Otherwise terminate

**Verification:** Agent turns when approaching obstacles instead of always dying.

---

## Phase 5: Feature Eligibility & Options System (45-60 minutes)

**Goal:** Implement the probability system for features (junctions, turns, stops).

### 5.1: Implement TunnelAgent:isEligibleForFeature()
**What it does:**
- Return true if stepsSinceLastFeature >= 8
- Return false otherwise

### 5.2: Implement TunnelAgent:calculateFeatureProbability()
**What it does:**
- If not eligible, return 0%
- Start at 2% base probability
- Increase linearly based on steps over minimum (reach 100% at 4x minimum distance)
- Return probability

### 5.3: Implement TunnelAgent:buildFeatureOptions(budget, terminationPressure)
**What it does:**
- Start with empty list
- Add "continue" option multiple times (high weight)
- If budget has junctions, add junction options (lower weight)
- If can turn left, add "turn-left" to budget and options
- If can turn right, add "turn-right" to budget and options
- If terminationPressure is high, add "stop" options
- Return list of option strings

### 5.4: Update TunnelAgent:step() with feature logic
**What it does:**
- If no collision, check eligibility and probability
- If feature should happen, build options and pick one
- Execute the chosen option (continue, turn, or stop for now - junctions in next phase)

**Verification:** Agent occasionally turns without needing a collision. Sometimes stops on its own.

---

## Phase 6: Junctions (60-90 minutes)

**Goal:** Make agents create junction spaces and spawn new agents from them.

### 6.1: Create Junction class (optional, or just use helper functions)
File: `breach/modules/game/world/junction.lua` (or add to TunnelWorldGenerator)

**What it contains:**
- Static method: `createJunction(builder, centerPos, width, height)`
- Digs out a rectangular space
- Returns the rectangle bounds for later reference

### 6.2: Implement TunnelAgent:createJunction(type, builder)
**What it does:**
- Calculate junction size based on distribution (70% small, 20% medium, 10% large)
- Position junction centered on current position (roughly)
- Dig out the rectangular junction space
- Return list of new agent spawn points based on junction type:
  - "straight": 1 exit on opposite side
  - "turn": 1 exit on perpendicular side
  - "3-way": 2 exits (opposite + one perpendicular)
  - "4-way": 3 exits (opposite + both perpendicular)
- Kill this agent

### 6.3: Update TunnelWorldGenerator to handle new agents
**What it does:**
- When stepping agents, collect any newly spawned agents
- Add them to the active agents list after iteration completes

### 6.4: Update TunnelAgent:step() to handle junction options
**What it does:**
- When "junction-*" option is chosen, call `createJunction(type, builder)`
- Return list of new agents to spawn

**Verification:** Agents create junction spaces and spawn new agents continuing in various directions.

---

## Phase 7: Termination Logic & Max Steps (30-45 minutes)

**Goal:** Implement the step budget system to prevent infinite generation.

### 7.1: Add step tracking to TunnelWorldGenerator
**What to add:**
- `totalSteps5Wide` counter
- `maxSteps5Wide` target (randomize in a reasonable range, start with ~500?)
- Method: `calculateTerminationPressure()` returns 0.0 to 1.0 based on how close to max

### 7.2: Update generation loop
**What it does:**
- Track total steps taken
- Pass termination pressure to agents when building options
- When pressure is 1.0, force all agents to terminate

### 7.3: Implement respawn logic
**What it does:**
- When all agents die, check if within 20% of target steps
- If yes, we're done
- If no, spawn a new agent at a random open floor spot away from other floors

**Verification:** Generation completes after a reasonable number of steps, creates multiple disconnected or connected tunnel networks.

---

## Phase 8: Collision Merge Logic (30-45 minutes)

**Goal:** When agents approach existing tunnels, allow them to merge instead of always turning or stopping.

### 8.1: Implement TunnelAgent:executeCollisionOptions(builder, budget)
**What it does:**
- Build list of options: "merge", "terminate"
- If canTurn(left), add "turn-left"
- If canTurn(right), add "turn-right"
- Weight merge heavily (like 60%), terminate (20%), turns (10% each)
- Pick option and execute

### 8.2: Implement merge behavior
**What it does:**
- Dig forward until connecting to the existing floor space
- Terminate the agent

### 8.3: Update collision handling in step()
**What it does:**
- Instead of always terminating or turning, call `executeCollisionOptions()`

**Verification:** Agents connect to existing hallways more naturally, creating loops and connections.

---

## Phase 9: 3-Wide Hallways (45-60 minutes)

**Goal:** After 5-wide hallways are complete, spawn and run 3-wide hallway agents.

### 9.1: Add pass 2 to TunnelWorldGenerator
**What it does:**
- After 5-wide pass completes, find spawn points along 5-wide hallways
- Look for straight sections without junctions nearby
- Spawn 3-5 agents with width=1 (effective 3-wide)
- Run similar generation loop with different parameters

### 9.2: Update TunnelAgent with width-specific behavior
**What it does:**
- If width == 1 (3-wide), use shorter minimum distances (~5 steps)
- If width == 1, have higher merge probability, lower junction probability
- 3-wide agents don't create junctions

### 9.3: Add 3-wide step budget
**What to add:**
- Similar maxSteps tracking for 3-wide hallways
- Separate termination pressure

**Verification:** After main hallways complete, smaller hallways branch off and create more connectivity.

---

## Phase 10: Polish & Tuning (30-60 minutes)

**Goal:** Make it feel good and handle edge cases.

### 10.1: Add bounds checking improvements
- Ensure junctions don't spawn partially out of bounds
- Ensure agents don't spawn too close to edges

### 10.2: Tune all the parameters
- Adjust probabilities, distances, counts based on visual testing
- Run generation 20+ times and tweak until it feels right

### 10.3: Add generation stats/logging
- Log number of junctions created, total steps, number of agents spawned
- Helps with debugging and tuning

**Verification:** Generation completes reliably, looks good, feels organic.

---

## Phase 11: 1-Wide Hallways (Optional - Future)

**Goal:** Add tiny connective hallways.

Similar to Phase 9 but for width=0 (effective 1-wide) hallways.

---

## Phase 12: Rooms (Future - Separate System)

**Goal:** Place rectangular rooms along hallway walls.

This is explicitly out of scope for the tunnel system and happens in a separate pass.

---

## Testing Strategy

After each phase:
1. Run the game with the MapGeneratorState visualization
2. Watch the generation step-by-step
3. Verify the new behavior works
4. Take notes on what looks wrong or weird

Keep the legacy system available so you can compare outputs.

---

## Estimated Total Time: 8-12 hours

Breaking it into these phases means you can:
- Stop after any phase and have working code
- Test incrementally
- Debug issues in isolation
- Ship partial implementations if needed

# ROOMS

Now we're going to do a final phase. In the remaining space, we need to carve out rooms. 

One naive approach is to simply attach rooms to hallways. We'll try that first. In open spaces next to hallways, we want to carve out as big a room space as we can fit. So look for eligible spots along hallways that have spaces larger than 4x4 adjacent that could fit a 3x3 room or greater. 

Sometimes this will be VERY large. Some designs don't have reliably hall penetration throughout the map. For now, that's okay.

Try to scale rooms up as big as can fit in a given space.

After generating a room, look for any other hallways or rooms that it is adjacent to, and then create one or more "doors" that link them together, i.e. one space wide floor spaces that allow flow between them. 

---

## Clarifying Questions

**Q1: Cell type for room interiors**
Should room floors use the same `Floor` cell as hallways, or should there be a distinct cell type (e.g. `RoomFloor`)? The current system has no way to distinguish a room tile from a hallway tile. Does that matter for gameplay (e.g. spawning, lighting, actor placement)?

> Answer: Just use Floor for now. We may change later.

**Q2: Minimum size threshold — interior vs. total**
The doc says "spaces larger than 4x4 adjacent that could fit a 3x3 room or greater." Is the intent that:
- (a) We require at least a 4×4 contiguous wall region available, and the minimum usable room carved from it is 3×3 interior (i.e. the 4×4 is the search gate, 3×3 is the smallest we'll actually place), or
- (b) Some other interpretation?

> Answer: Yes, rooms must have a 1 width "wall" around them minimum. So 4x4 search area includes space to contain a 3x3 room with one cell walls.

**Q3: Maximum room size**
"Scale rooms up as big as can fit" — should there be a hard cap on room dimensions (e.g. 12×12, 20×20), or truly no upper bound beyond the map edge? Very large uncapped rooms could swallow most of the map on sparse hall layouts.

> Answer: The limit is about aspect ratio. Do not allow rooms with an aspect ratio of greater than 3/1 in either direction. So get as big as you can without violating that.

**Q4: Room shape**
Strictly axis-aligned rectangles only, or can rooms be L-shaped / irregular if the open space is that shape?

> Answer: Start with axis-aligned rectangles. We may create the other shapes later by knocking down more walls between rooms.

**Q5: Candidate spot scanning strategy**
How should we find eligible spots — scan every floor tile along every hallway and check all four perpendicular directions, or randomly sample like the tunnel respawn logic? And should we try every candidate or stop after placing N rooms?

> Answer: Randomly sample. Stop when you either fail to find new place to place enough samples in a row, or we hit a total floor fraction above 75%.

**Q6: Room count / coverage budget**
Is there a target number of rooms, a maximum floor-coverage fraction (like the hallway passes have), or should we simply place a room at every eligible spot that fits?

> Answer: Just a ratio overall,

**Q7: Overlap / reservation**
Once a room is carved, should the space be "reserved" so no second room can overlap it? (Presumably yes, but: should rooms be allowed to merge/expand into each other, or are they always kept separate?)

> Answer: Yes, reserve it's space going forward. Another room needs space for its wall to be placed.

**Q8: Door count and placement**
When a room is adjacent to a hallway or another room, how many doors should be punched through the shared wall — exactly one, or potentially several? If one, should it be placed at the midpoint of the shared edge, or randomly along it?

> Answer: Calculate how many are possible, assuming each door is two wide, and then pick a random number between 1 and half of the max. 

**Q9: Room-to-room doors**
If two rooms end up directly wall-adjacent to each other (not connected through a hallway), should they get a door linking them? Or only room↔hallway connections?

> Answer: Yes, that's a fine outcome.

**Q10: Visualization / coroutine yield**
Should the room-placement pass call `coroutine.yield()` after each room (or each candidate scan) so it shows up step-by-step in the `MapGeneratorState` visualization, consistent with the tunnel passes?

> Answer: Yes.

