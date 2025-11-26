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

1. Make a text crawl animation. Takes x, y, string, duration OR delay. Animates it in. (learn option parameters for this). 
1. Make a text flash animation? This may be trivial but good to standardize in one place. (how would it end in ON mode? if we wanted a flicker->on, and/or flicker->off)
   What is this exactly? Takes string, fg,  bg, location, flash frequency, flash count? 
1. Animate + fade animation. Like a health loss notice. -1, -2, etc. Float multiple tiles up. 
   a. Add fade. 

# Animation Ideas
 1. Sparking particle (controls: direction, frequency, color, index)
   a. This would be an in-world animation, not an overlay/screen coordinate particle. 
 1. Explosion
 1. Line (multiple waypoints??)

# Scenes

At some point, set up multiple scenes.

Q: How do Displays fit in? I recall passing Displays around scenes, which we may want to retool. 

1. An ImageState class that takes a base image. Add a shared(?) keyboard map for navigation. (This is for title screen, victory, death, instructions, etc.)
2. The PlayState which is heavily custom. Eventually there will probably also be MenuScenes and LoadoutScene or ShopScene or whatever.


# Systems

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

## Fire

How similar is it to smoke? Are there concepts that work for both of these? Volume spreading could be shared, with volume ALSO generating from certain tiles? Like if you hit a flammable thing. (This is a push away from Tile). 

It seems right to say "A tile can be on fire" which implies component. 



# Backlog

1. (DONE) Find a better 32x32 font?? This has been weirdly hard.
   a. alternatively, use the 20x20 CP437 but scale it so they're in the middle of 32x32 cells. 
   b. or, build out a simple tile map and focus on trying atlas as a toolchain and make some simple items so we're back visual again. (I like the simplicity of ASCII for prototyping and bring in graphics later, but the complete lack of an acceptable 32x32 font has been a real blocker for this.)
   c.
1. System play:
   a. Smoke that disperses over time and blocks vision
   b. Fire that spreads(?) and does damage but does not block vision
   c. Oil spill?? Something that you can't move through, but you can see through? Spikes on the floor?
   d. Doors?? Open when you get close??
   e. Something slipping?
