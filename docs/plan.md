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
 1. Explosion
 1. Line (multiple waypoints??)

# Scenes

At some point, set up multiple scenes.

Q: How do Displays fit in? I recall passing Displays around scenes, which we may want to retool. 

1. An ImageScene class that takes a base image. Add a shared(?) keyboard map for navigation. (This is for title screen, victory, death, instructions, etc.)
2. The GameScene which is heavily custom. Eventually there will probably also be MenuScenes and LoadoutScene or ShopScene or whatever.
