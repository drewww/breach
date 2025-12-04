# BREACH

The first phase is all about basic infrastructure.

# Display

1. (done) Set up multiple spritesheets
    a. start with the wanderlust 16x16
    b. cp437 32x32 with ASCII atlas
    c. (eventually) an actual "native" tileset using composed MRMOTEXT tileses
2. (done) Migrate the basic display to 32x32
3. (done) Layer another display at 16x16 and test it

We will not want an infinite number of displays and spritesheets. It would be repetitive to re-declare them between scenes. So maybe we create them up top, and pass in two versions. There's a MacroDisplay (32x32) and an OverlayDisplay (16x16).

## Extensions

Make some basic animations. An overlay animations file can store this.

1. DONE Make a text crawl animation. Takes x, y, string, duration OR delay. Animates it in. (learn option parameters for this). 
1. DONE Make a text flash animation? This may be trivial but good to standardize in one place. (how would it end in ON mode? if we wanted a flicker->on, and/or flicker->off)
   What is this exactly? Takes string, fg,  bg, location, flash frequency, flash count? 
1. DONE Animate + fade animation. Like a health loss notice. -1, -2, etc. Float multiple tiles up. 
   a. Add fade. 

# Animation Ideas
 1. Sparking particle (controls: direction, frequency, color, index)
   a. This would be an in-world animation, not an overlay/screen coordinate particle. 
   b. Actually, the overlay is currently working in world coordinates not screen. So, TODO get it working in screen coordinates also. 
 1. Explosion
 1. Line (multiple waypoints??)

# Scenes

At some point, set up multiple scenes.

Q: How do Displays fit in? I recall passing Displays around scenes, which we may want to retool. 

1. An ImageState class that takes a base image. Add a shared(?) keyboard map for navigation. (This is for title screen, victory, death, instructions, etc.)
2. The PlayState which is heavily custom. Eventually there will probably also be MenuScenes and LoadoutScene or ShopScene or whatever.


# Systems

What other environmental effects are interesting? Electrical linkage between doors / terminals / turrets / ??? 

## Smoke

What IS smoke? We have three options.

1. Tile -- probably not, because when the smoke is gone the tile is stil there.
2. Actor -- could be, since we'll need some system and it has some state.
3. Component -- also could be.

What capabilities do we want with smoke?
1. (done) It dissipates after N turns.
2. (done) It blocks vision. 
3. (done) It is passable.
4. (done) If you're inside it, it does not block vision. 

Reach ideas:
1. It can spread naturally. IE it starts in a tile with volume=15 and then it randomly spreads its volume in adjacent passable tiles. 
1. Like counterstrike, if you shoot a projectile through it, you can clear it.

Back to Actor or Component. Components can't themselves be blocking vision or be impassable. So I think it's actor. 

So, implementation plan:
1. (done) Make a Smoke actor that is passable but blocks vision.
1. (done) Make an ExpirationSystem that looks for Expiring components. 

Now to visualize smoke densities. LERP between WHITE and Dark Grey on some smoke scale. 0-100 to start, I guess. But where does this happen? I guess when we set it in the system. It could be in the controllers, also. Hmm. 

Do I want multiple gasses? Options:
   1. Smoke -- Diffuses relatively slowly and not super far. Can't see through when dense.
   1. Fire -- See through, take damage if you walk into. High dissipation rate, high spread rate, low retain rate. Waves of stuff. 
   1. Poison Gas? -- See through, move through, lower damage. Slow dissipation, spreads far. 
   
Other evironmental effects might not dissipate this way, like something that's transparent but collideable. The only spreadable versions of this are like ... electrified water? A slick something? 

Flow fields. The specific experiences I want are to shoot a pipe and make a jet spurt out. This could just be simulated by emitting a bunch of smoke along a line once. I don't NEED to simulate the flow. Would there be interesting interactions with the flow? Moving through can create flow, but hard to sense it. Shooting through could create flow, but also we could just clear gas with a shot. Explosions could edit the flow field, but it's confusing. Okay so no flow fields. 

The thing to do now is abstract to multiple gas types. That means we need in the Gas Component:
   1. gas types -- we have to make a map per gas type, and we have gas-specific diffusion parameters

Then in the diffusion system, we need to run the process for each gas type we know. Fully abstracted. 

The final issue is how to represent multiple gasses in one tile. I'd like to cycle through them in the display. Each second is split among them. Set up looping custom animations per tile that alter the layers? Practically this is not a huge issue, actually. How often will it happen? Damaging types should take precedence on layer and it's good enough. FIre > gas > smoke. 

## Fire

How similar is it to smoke? Are there concepts that work for both of these? Volume spreading could be shared, with volume ALSO generating from certain tiles? Like if you hit a flammable thing. (This is a push away from Tile). 

It seems right to say "A tile can be on fire" which implies component. 


# Doors

I think this is a controller, basically. If it senses an entity on either side, open. If it is open and cannot sense someone adjacent, close. (maybe optional disdtances)

Path:
   1. DoorController

## Linked Doors

This got tricky. The second door DOES get an open command, but then it senses a lack of a person and closes itself immediately. How to solve?

Options:
   - set a flag, that's like "forced open"
   - doorcontroller can have a field which is "sensesMover" and each one checks all their links and opens if any of them is true
      - problem with THIS is that they are only linked adjacently, so they would need to crawl the entire tree of linked doors every cycle. 
      - so therefore, all doors need all other doors to be linked on create.

I'm close. The issues are:
 1. The auto-discovery seems made broken. Could fix that.
 2. Could pull it out into a system. The system has an issue with timing. It has to run after every door and check if all its linked doors are done. Which is barely better than having roughly the same logic inside each door controller.
 3. We could do it after an entity moves ... check if any door sees the entity. If it does, open that door and any linked doors. (requires solution to the linking problem). 
 4. Make an action called on every door every post-move which is "checkdoor"? This will solve the timing issues. But it will run much more often. It's roughly the same as what we have now, except it puts the checking logic into an action. 
 
 This has gotten not-fun. It works for 2, let's simplify back down to that case and if we really want to do 3,4,5-wide doors we can build it later. The easiest answer is to have a single doorsensor per group and just pre-build it that way. So that the door sensor finds all adjacent doors on act, and sends them all actions. 

# Enemies

What would be interesting here? First, having a "patrol" behavior separate from simply waiting around.
   1. (DONE) Create an Enemy controller.
   2. (NOT YET) Explore behavior trees.
   3. (DONE) Probably make it randomly explore locally. 
   4. Basic state machine: PATROL, HUNT
      a. PATROL picks random passable destinations in the world and paths to them.
         later destinations should be nav points
      b. if you see a player, move towards them (or the last place you saw them) 
      c. SEARCH mode? if you get to a place you saw a player and can't find them, start spiral searching. Or set way points roughly 8-way around, pick a random one to start and then clockwise it? 
      d. 
      a. then add SEARCH (need to figure out a trigger for this; another enemy reporting a sighting? how?)
   
   Let's think a little about a how a simple BT might work.
   
   1. Root
      Sequence
   
   First, NODES.
    - move
    - shoot
    - target (apply shoot intent?)
    - reload
    - flee
    - hunt
   
   The most basic BT is just a root note that calls move every turn and move picks randomly. 
    
         
   
   Stretch: multiple enemies with relations that choose together. 
      so we could have a leader type which picks destinations and broadcasts them?
      and then follower types that have a vector relative to the leader that they try to maintain. 
         for this to be really cool, we'd want it to be relative to leader movement direction, i.e -2, -2 relative to facing. 
         so do to do this
            - build facing, updated on each move
            - use waypoint system for leader as is
            - followers find the nearest leader on spawn and trail it? 
               how do followers know which spots are open? 
            - we're back in a distributed systems problem. 
            - well atually the leader just keeps a list of available slots and assigns on follower spawn
            - now mechanically how does this work. FindLeader behavior.
            - a component on leaders that manages open slots
            - what if leader moves after a follower? it's okay.
         if we DO need active communication, how does it work? for example breaking out of follower mode. I guess we set a component on the leader and then followers pick it up?? 


A tracking behavior if it has a seentarget. 

Then maybe something clever like Flanking? Or a ranged attack behavior?

Basically just messing around in this zone. 

An eventual thing might be squads with different weapons. 

Can you kill a "scout" type quickly enough that it doesn't broadcast your location?? 

# Damage

Only way to do damage at the moment is Fire or Gas. Could add damage checks to that. 

I like the "scorch" idea where colors on certain environmental things change as a result of effects. Question -- do I collapse this into Damage as an action? Or should it be a separate action? Could non-damaging effects cause lingering color?

It's a little weird to be passing a color into damage. Seems like a separate KIND of thing. It could be double triggered. Then the question is does Damage trigger it by default? Or should the thing DOING damage hae to do the check? 

Part of it is that right now, I'm passing the color scorching effect in as a target parameter. The example code for Attacker looks at the component source of the attack. Eventually, we'll be looking at the weapon doing the attack and it may have a "scorch" component we can use. But for now it's a little awkward.

(DONE) So -- for first version, do it in damage. Then, break it into ScorchAction, called from damage. Eventually remove it from the target when Weapons are real first class actors.

# Moves

Prototyped the dash mechanic, no cooldown. It's okay for now. It needs a complete refactor though. There's this emerging pattern that there need to be decision engines that decide what moves are valid, and then they feed both the UI and the internal destination logic. It's too distributed right now. In one place we need to take the player's position, and the world, and return valid destination tiles for each of the valid vector inputs. 

Also, consider starting to rebuild the animation for moving multiple tiles so it stops in the intermediate tiles. Shouldn't be too bad. 

Consider learning how mixins work, or some other way entirely to modularize this. It's totally entwined now in weird ways. I'm not sure if this is the feature to figure this out for, but maybe. 

DONE -- consider the structural refactor. It'll be a good learning exercise. Then, go to enemies. 

As for the flashing... I'm truly at a loss. It may just be something hacky like queing the update into the next draw frame so we skip one while the camera moves and then settle in at the new location? 

TODO -- integrate a smoothly updating camera. That will be huge. Probably will inherit this from the prism devs over the coming days, so don't do too much exploration there now.

# Backlog

1. (DONE) Find a better 32x32 font?? This has been weirdly hard.
   a. alternatively, use the 20x20 CP437 but scale it so they're in the middle of 32x32 cells. 
   b. or, build out a simple tile map and focus on trying atlas as a toolchain and make some simple items so we're back visual again. (I like the simplicity of ASCII for prototyping and bring in graphics later, but the complete lack of an acceptable 32x32 font has been a real blocker for this.)
   c.
1. System play:
   a. (done) Smoke that disperses over time and blocks vision
   b. (done) Fire that spreads(?) and does damage but does not block vision
   c. (not doing) Oil spill?? Something that you can't move through, but you can see through? Spikes on the floor?
   d. (DONE) Doors?? Open when you get close??
   e. Something slipping?
1. (NEXT) Reimplement movement, play with "roll" versus teleport model?
1. Gas emitters
1. Reimplement guns? (this is a big thing)
1. Go back to enemies, and learn behavior trees. (curious about this but I need more actions for them to take than pure movement. might need shoot actions. or maybe it's enough to do a kind of patrol / search / attack loop of some kind?? )
1. Consider making an action for Gas getting removed, because there may be some relevant shared logic there eventually?
1. (DONE) Make Damage action, which could turn into fire damage making walls get scorched or doors failing open. 
1. (DONE) Consider making double-wide doors that open/close together. I think using some sort of relationship method??
1. Start a light UI framework.
   a. Requires getting overlay to work in screen coordinates.
   b. (and to simultaneously handle world coordinate draws as well??)
   c. Some simple object structure that lets me write UI things with useful screen coordinates and access to the level for updates.
1. (NOT DOING) Make the gas objects into a real object. 
1. (DONE) Add a natural gas one?? No damage, can be lit on fire.
1. Make the gas generator objects: (this does need something to trigger it ... so we need a damage application UI first)
   a. fuel line that spurts gas for N turns
   b. canisters of different types
   c. weapons that generate smoke / fire? 
   d. strange machines that just puff poison or fuel or smoke?
