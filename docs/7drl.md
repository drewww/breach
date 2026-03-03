# 7DRL

High level clusters of work to do:
   - [done] world generation
   - world decoration
      - the most critical piece here is things that drop loot or weapons
      - some sort of time-release thing
   - mechanisms for spawning enemies
   - enemy behaviors
      - patrol
      - seek
      - reload
      - flank?? 
      - ask for help
   - make more enemies
      - "boss" type enemies that take a lot more damage / have armor, that you have to work harder to take down
         - that have better loot
      - 
   - make more items for the player
      - mines the bots can't "see"
      - trip mines? 
      - longer-range weapons? 
      - upgrades to your abilities?
         - +1 range to weapons?
         - energy/movement-related upgrades
         - armor
         - push-resist
         - health regen, max health
         - 
   
   - get loot drops working
   - consider spawning in more enemies
   - double back to tutorial


## DAY 1

We've mostly got a world. At minimum we've got working hallways, with a little bit more polish. 

Optional flourishes:
   - show where the model is checking for things, that would be a cool list to visualize in the animation.

## DAY 2

 - [done] Get rooms working, assuming we don't get it done on Day 1.
 - [done] Add door entities.
 - [done] Merge back into playstate, and see if we can get the game to load in that world and walk around in it. 
 - [done] Try doing a pass where we add variation in the tiles visually?
   - basically for wall tiles, select random ones, and get the iso perspective thing in where if it's the "bottom" most tile adjacent to a floor, swap in the variant.
   - for floor tiles, randomize?? or different tiles for hallway and rooms
- mechanism for spawning enemies
   - eventually we probably want them spawning in periodically in response to stimuli
   - but there should be some initial condition.
   - spawn them in rooms or hallways??
      - there are maybe "guard" type rooms we should create
   - they should be adjacent to vaults, actually. 
   - so two types of spawning:
      - room spawns (with a vault present)
      - hallway spawns (on patrol mode)
- more enemy variation + behvaior
   - patrol mode
      - put waypoint hits into the map in hallways. follow those around.
- who are my test bots?
   - burst bot to start? give it no vision 
   - we gotta rebuild the burst bot actually with sight-responsive seeking the player
   - and then we'll cut its sight to 0 and use that for patrol testing
- so TASKS
   - make the "see it, go to it, last known" -- etc behavior
      - [done] if you see the player, store the location in your blackboard
      - if you see the player and are in range, shoot
      - if you see the player and are not in range, move into range.
         - the MoveToPlayer behavior is interesting, but we'll need to think about how to supercede it to move towards other destinations 
      - if you do not see the player, but have a known location in blackboard, move in that direction
   - attach it to burst bot
   - give it vision, test in geometer spawning
   - then add patrol hints
   - then add patrol behaviors
   - see if they can co-exist using low vision distance
