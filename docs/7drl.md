# 7DRL

High level clusters of work to do:
   - world generation
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

 - Get rooms working, assuming we don't get it done on Day 1.
 - Add door entities.
 - Merge back into playstate, and see if we can get the game to load in that world and walk around in it. 
 - Try doing a pass where we add variation in the tiles visually?
   - basically for wall tiles, select random ones, and get the iso perspective thing in where if it's the "bottom" most tile adjacent to a floor, swap in the variant.
   - for floor tiles, randomize?? or different tiles for hallway and rooms
- 
