# Waypoint System

This document describes the waypoint placement system used in the TunnelWorldGenerator to create navigation points for AI agents.

## Overview

Waypoints are special floor tiles marked with the `Waypoint` component. They serve as navigation markers for AI bots (like `RandomWaypointBot`) to pathfind through the generated facility. The system automatically places waypoints at strategic locations during world generation, including periodically along hallways every 5 steps.

## Waypoint Cell Type

**Cell Type**: `prism.cells.WaypointFloor()`

This is functionally identical to a regular floor tile but includes the `prism.components.Waypoint()` component, making it discoverable by AI navigation systems.

## Automatic Placement Locations

Waypoints are automatically placed in five key locations:

### 1. Hallway Start

**Location**: At first dug position  
**File**: `tunnelagent.lua` → `step()`  
**Placement**: After agent digs initial position, before moving forward

**Purpose**: Marks the entry point of a hallway segment (placed after dig to avoid being overwritten).

### 2. Hallway End

**Location**: Final position when agent terminates  
**File**: `tunnelagent.lua` → `step()`  
**Placement**: When termination pressure reaches 100% or agent dies

**Purpose**: Marks the exit/end point of a hallway.

### 3. Periodic Along Hallways

**Location**: Every 5 steps along straight hallway sections  
**File**: `tunnelagent.lua` → `step()`  
**Placement**: After digging, before moving forward, when `stepsSinceLastWaypoint >= 5`

```
Hallway with periodic waypoints (W):
═══W════W════W════W════W════W═══
```

**Purpose**: Ensures consistent waypoint coverage for navigation along long hallways.

### 4. Hallway Turns

**Location**: Apex (center) of each turn  
**File**: `tunnelagent.lua` → `applyTurn()`  
**Placement**: After agent rotates and completes all turn digging

```
Before Turn:          During Turn:         After Turn (W = waypoint):
═════════             ═════════            ═════════
    ║                     ║                    ║
    ║                     ║                    ║
    ║                     ╚════W              ╚════W════
    ║                                                 ║
    ║                                                 ║
```

**Purpose**: Marks decision points where bots can change direction.

### 5. Junction Centers

**Location**: Center cell of each junction  
**File**: `tunnelagent.lua` → `executeJunction()`  
**Placement**: After carving out the junction space

```
Junction (W = waypoint in center):

    ║     ║
    ║     ║
════╝     ╚════
    ┌─W─┐
════╗     ╔════
    ║     ║
    ║     ║
```

**Purpose**: Central navigation point for multi-directional movement through junctions.

### 6. Junction Central Pillar Corners

**Location**: Four corners around central pillar, inset 1 cell from junction walls (close to corners)
**File**: `tunnelworldgenerator.lua` → `fillJunctionCentralPillar()`  
**Placement**: After pillar is placed, only for "central_pillar" junction type

```
Junction with Central Pillar (W = waypoints, ▓ = pillar):

         ║    ║    ║
         ║    ║    ║
═════════╝    ║    ╚═════════
                           
 W             ▓▓▓             W
 (inset=1)     ▓▓▓     (inset=1)
               ▓▓▓            
                           
 W             ▓▓▓             W
                           
═════════╗    ║    ╔═════════
         ║    ║    ║
         ║    ║    ║
```

**Purpose**: Provides navigation points near corners around obstacles, allowing bots to path around the pillar in multiple directions.

## Implementation Details

### Periodic Waypoint Placement

```lua
function TunnelAgent:step(builder, terminationPressure)
   -- Dig at current position
   self:dig(builder)
   
   -- Place initial waypoint at hallway start (after dig, before move)
   if not self.initialWaypointPlaced then
      builder:set(self.position.x, self.position.y, prism.cells.WaypointFloor())
      self.initialWaypointPlaced = true
      self.stepsSinceLastWaypoint = 0
   end
   
   self.stepsSinceLastWaypoint = self.stepsSinceLastWaypoint + 1
   
   -- Place periodic waypoints every 5 steps (after dig, before move)
   if self.stepsSinceLastWaypoint >= 5 then
      builder:set(self.position.x, self.position.y, prism.cells.WaypointFloor())
      self.stepsSinceLastWaypoint = 0
   end
   
   -- Move forward
   self.position = self.position + self.direction
end
```

Waypoints are placed every 5 steps along hallways, after digging but before moving forward. This prevents them from being overwritten on the next step. The counter resets when turns or junctions place their own waypoints.

### Hallway Start/End Waypoints

```lua
function TunnelAgent:step(builder, terminationPressure)
   -- Dig at current position
   self:dig(builder)
   
   -- Place initial waypoint at hallway start (after dig, before move)
   if not self.initialWaypointPlaced then
      builder:set(self.position.x, self.position.y, prism.cells.WaypointFloor())
      self.initialWaypointPlaced = true
   end
   
   -- Move forward
   self.position = self.position + self.direction
   
   -- Place waypoint at end when terminating
   if terminationPressure >= 1.0 then
      builder:set(self.position.x, self.position.y, prism.cells.WaypointFloor())
      self.alive = false
   end
end
```
</text>

<old_text line=200>
function TunnelWorldGenerator:fillJunctionCentralPillar(junction)
   -- ... place central pillar ...
   
   -- Place waypoint floors in the corners, inset by 1 from walls (close to corners)
   local inset = 1
   local corners = {
      { x = x + inset,         y = y + inset },        -- Top-left
      { x = x + w - inset - 1, y = y + inset },        -- Top-right
      { x = x + inset,         y = y + h - inset - 1 }, -- Bottom-left
      { x = x + w - inset - 1, y = y + h - inset - 1 }  -- Bottom-right
   }
   
   for _, corner in ipairs(corners) do
      builder:set(corner.x, corner.y, prism.cells.WaypointFloor())
   end
end
```

Four waypoints are placed in the corners of the junction, inset by 1 cell from the walls. This places them close to corners for better navigation around the pillar.

### Turn Waypoint Placement

```lua
function TunnelAgent:applyTurn(builder, turnDirection)
   -- ... rotation logic ...
   
   -- Save apex position for waypoint placement
   local apexX, apexY = self.position.x, self.position.y
   
   -- Do width digs forward, clearing the corner
   for i = 1, self.width do
      self:dig(builder)
      self.position = self.position + self.direction
   end
   
   -- Place waypoint floor at the apex of the turn (after all digging)
   builder:set(apexX, apexY, prism.cells.WaypointFloor())
   self.stepsSinceLastWaypoint = 0
end
```

The waypoint is placed at the apex of the turn AFTER all digging is complete. The apex position is saved before digging forward, then the waypoint is placed at that position after all the turn's dig operations finish. This prevents the waypoint from being overwritten.

### Junction Waypoint Placement

```lua
function TunnelAgent:executeJunction(builder)
   -- ... carve junction ...
   
   -- Place waypoint floor at the center of the junction
   builder:set(self.position.x, self.position.y, prism.cells.WaypointFloor())
   
   -- ... spawn new agents ...
end
```

The waypoint is placed at the junction's center point after the entire junction area has been carved out.

### Central Pillar Corner Waypoints

```lua
function TunnelWorldGenerator:fillJunctionCentralPillar(junction)
   -- ... place central pillar ...
   
   -- Place waypoint floors in the corners, inset by 2 from walls
   local inset = 2
   local corners = {
      { x = x + inset,         y = y + inset },        -- Top-left
      { x = x + w - inset - 1, y = y + inset },        -- Top-right
      { x = x + inset,         y = y + h - inset - 1 }, -- Bottom-left
      { x = x + w - inset - 1, y = y + h - inset - 1 }  -- Bottom-right
   }
   
   for _, corner in ipairs(corners) do
      builder:set(corner.x, corner.y, prism.cells.WaypointFloor())
   end
end
```

Four waypoints are placed in the corners of the junction, inset by 2 cells from the walls. This provides clearance from walls while still marking navigation points around the pillar.

## Bot Navigation

Bots with waypoint-based AI (like `RandomWaypointBot`) can:
1. Query the level for all `Waypoint` components
2. Select waypoints as navigation targets
3. Pathfind between waypoints
4. Create patrol routes or random wandering patterns

Example bot setup:
```lua
prism.registerActor("RandomWaypointBot", function()
   return prism.Actor.fromComponents {
      prism.components.Name("RandomWaypointBot"),
      prism.components.BotController(),
      prism.components.Senses(),
      prism.components.Sight { range = 8, fov = true },
      prism.components.Mover { "walk" },
      -- ... other components
   }
end)
```

## Coverage Statistics

After world generation, waypoint coverage typically includes:
- **Hallway starts**: 1 waypoint per agent spawned (typically 5-15 total)
- **Hallway ends**: 1 waypoint per agent termination (typically 5-15 total)
- **Periodic**: 1 waypoint every 5 steps along hallways (highly variable, typically 50-200+ per map)
- **Turns**: 1 waypoint per turn (varies by generation, typically 3-10 per agent)
- **Junctions**: 1 waypoint per junction center (typically 2-6 total)
- **Pillar Corners**: 4 waypoints per central pillar junction (if any, typically 0-12 total)

**Total**: Approximately 100-300+ waypoints per generated map, depending on complexity and hallway length.

The majority of waypoints come from periodic placement along hallways, ensuring comprehensive navigation coverage throughout the facility.

## Visual Identification

In-game, waypoint floors appear identical to regular floor tiles to the player. However, they are internally tagged with the `Waypoint` component, making them discoverable by AI systems.

To visualize waypoints during development:
- Use Geometer editor mode to inspect cell components
- Query the level for `prism.components.Waypoint` to count/locate them
- Add debug rendering to highlight waypoint cells

## Future Enhancements

Potential improvements to the waypoint system:
1. **Room waypoints**: Add waypoints inside generated rooms
2. **Weighted waypoints**: Priority values for tactical positions (cover, choke points)
3. **Linked waypoints**: Pre-computed adjacency graphs for faster pathfinding
4. **Dynamic waypoints**: Runtime-added waypoints based on gameplay events
5. **Waypoint types**: Different waypoint categories (patrol, guard, hide, etc.)

## Related Components

- `prism.components.Waypoint` - Component marking a cell as a waypoint
- `prism.cells.WaypointFloor()` - Floor cell factory with waypoint component
- `prism.components.BotController` - AI controller that can use waypoints
- `prism.behaviors.RandomWaypointBehavior` - Behavior tree node for waypoint navigation