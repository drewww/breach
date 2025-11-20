# BREACH

The first phase is all about basic infrastructure.

# Display

1. Set up multiple spritesheets
    a. start with the wanderlust 16x16
    b. cp437 32x32 with matching atlas
    c. (eventually) an actual "native" tileset using composed MRMOTEXT tileses
2. Migrate the basic display to 32x32
3. Layer another display at 16x16 and test it

We will not want an infinite number of displays and spritesheets. It would be repetitive to re-declare them between scenes. So maybe we create them up top, and pass in two versions. There's a MacroDisplay (32x32) and a MicroDisplay (16x16).

# Scenes

At some point, set up multiple scenes.

Q: How do Displays fit in? I recall passing Displays around scenes, which we may want to retool. 

1. An ImageScene class that takes a base image. Add a shared(?) keyboard map for navigation. (This is for title screen, victory, death, instructions, etc.)
2. The GameScene which is heavily custom. Eventually there will probably also be MenuScenes and LoadoutScene or ShopScene or whatever.
