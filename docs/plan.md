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
   What is this exactly? Takes string, fg, bg, location, flash frequency, flash count?
1. DONE Animate + fade animation. Like a health loss notice. -1, -2, etc. Float multiple tiles up.
   a. Add fade.

# Animation Ideas

1. Sparking particle (controls: direction, frequency, color, index)
   a. This would be an in-world animation, not an overlay/screen coordinate particle.
   b. Actually, the overlay is currently working in world coordinates not screen. So, TODO get it working in screen coordinates also.
   (actually; overlay is now ONLY doing world coordinate animations now. so if you wanted screen coordinates you'd have to undo the camera offset manually, I think(?))
1. Explosion
1. Line (multiple waypoints??)

# Scenes

At some point, set up multiple scenes.

Q: How do Displays fit in? I recall passing Displays around scenes, which we may want to retool.

1. An ImageState class that takes a base image. Add a shared(?) keyboard map for navigation. (This is for title screen, victory, death, instructions, etc.)
2. The PlayState which is heavily custom. Eventually there will probably also be MenuScenes and LoadoutScene or ShopScene or whatever.

# Interface

What do I want out of this?

1. Encapsulation
1. Coordinate safety + independence, so I can choose where it goes

What does it need?

- Access to level
- Access to a display

How do animations work? Like responding to events. Let's say you press 'i' and inventory needs to come up.

Well one answer is it's always "up" but just not given access to display. But that's not a complete answer, lots of stuff will change state of something. If it only changes state of the WORLD then auto-updating via level is great. But there will be UI things. At some point we do a full other state like the inventory example.

So it's not a display subclass. Now how does drawing work? Could I abuse camera? Set the camera, start the camera, draw a bunch, stop the camera? But I'm using a camera that gets me screen coordinates?

What do I call this? Frame or Panel

Is it a subclass of anything? Just Object I think.

Then when it's draw time, is there something in OverlayDisplayState that we leverage? We could track panels there.

# Systems

What other environmental effects are interesting? Electrical linkage between doors / terminals / turrets / ???

- power conduits that the player struggles to damage but enemy weapon types damage easily?
- or maybe it's like it takes two shots from two different damage types; to break the "armor" and then disrupt it
- basically require certain things to be powered and make the power lines visible somehow
- power lines could be in the floor??

# Gas

What IS smoke/gas? We have three options.

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

At the moment, gas doesn't spread into actor-occupied cells because they have colliders. On the one hand, we don't want to expand through walls. So I guess we need Impermeable to mark walls separate from actors.

## Fire

How similar is it to smoke? Are there concepts that work for both of these? Volume spreading could be shared, with volume ALSO generating from certain tiles? Like if you hit a flammable thing. (This is a push away from Tile).

It seems right to say "A tile can be on fire" which implies component.

## Emitters

1. (done) Duration? Auto-run out and remove the emitter component?
2. (done) Frequency?
3. (not done) Ramp:
   a. Could do this with an animation that "fakes" steam appearing quickly as it spreads out of the source.
   b. Could do this as a "ramp" on the templates, such that it counts turns emitted (via duration mechanics) and covers more template spaces each turn.
   1. This gets complex in situations that are not purely a line. Some complex data structure with turns it enables. But not THAT bad. The tradeoff is that it's kinda slow to take effect in a sense.

To help decide let's consider other emitters:

1. Emit when taking damage. Unrelated; that's another damage effect capability.
2. A rocket that moves N spaces and leaves smoke behind? This could be a gas emitter, although it would need Facing to work. Tricky.
3. A damaged machine that puffs occasionally to show what it is processing??
4. A barrel that explodes into something? Not really an ongoing emitter.
   This could be a duration 1 emitter, actually. The issue is how to trigger it. Do we trigger on ANY damage or death? Might be two fields: threshold, onDamage. Problem becomes if you want two different emitter patterns. And actually, on-death is hard because the emitter won't still exist. So we need some other on-death thing.

Okay so actual todos -- the emission characteristics above. And then make actors that:

1. Puff occasionally
1. Puff on damage
1. Puff "behind" while moving?

TODO -- some mechanism to trigger a damage effect that's not hard-coded. How do we want to do that?

1. Make a DamageReaction superclass of components, which all have a "damaged()" callback that the Damage action calls.
2. Can I put an action factory on DamageReaction? Will that safely serialize? And have Damage just make that action and try to call it?

# Abilities

Entities in the world have various capabilities. This includes: shoot (many many variations of this one), throw grenade, drop a mine, trigger a shield, burrow through a wall, and so on.

We want these capabilities associated with items, because these capabilities will shift over the course of a run / game. A player may pick and equip items and change their capabilities.

A player may also have limits on the kind of equipment they can use simultaneously. For example a given chassis might have space for 2 weapon hardpoints, one utility item, and one defensive item. (Or we may express this in some other "size" mechanism, like you have two 4x2 cells to mount on, one 5x1 cell, and one 3x3, and then some system of creating different sized items that can be assigned to them.)

This immediately suggests many kinds of components. Ideally there is some sharing of capabilities. For example, Range is an obvious one; weapons and defenisive items might share this. Another might be Ammo. Some items will have shared "pools" of ammo like "energy cartdrige" or "pistol ammo." Others will be self-stackable, for example grenades. Some weapons might have energy costs to fire them. So, broadly, there is some sort of "Cost" component. Cooldown might be another component.

So let's think out loud about this. Let's say we have an "Ability" action. It's the top level container that checks all the precursors. The item would have an "Ability" component. The ability action would take an item with the ability component.

It would:

- Run through a list of constraint-type components: range, cooldown, cost. This all sits in "canPerform" and we can set defaults. If no range specified, any range is okay.
   - Make sure to communiate why things fail clearly! We will need to reflect this back into the player UI.
   - How do we think about something like the shotgun? It has a damage template, damage type. In that case, the UI is simply setting the angle not the distane. So does it have a range limit? Hard tos ay.
- If valid, then we:
   - Apply the costs component.
   - Pull the Template (single tile, a line, an AOE, etc.)
   - Pull the DamageType (push, ap, basic, how much, etc.)
   - Apply damage in Template.

How do we think about reload as an action? I guess there's a Reloadeable component, or it's contained in the Costs component. If the reload input is triggered, check and see if you need to do it.

Let's think through how some examples would be expressed in these terms.

- Pistol
   - Cost: 1 pistol ammo
   - Range: 10
   - Template: 1x1
   - Effect: 1 hp, 1 push
- Smoke Grenade
- Cost: 1 ammo "smoke grenade"
- Range: 5
- Template: AOE 4
- Effect: Spawn Actor "smoke" volume 10
- Grenade Launcher
- Targeting: bounce,

Does grenade behavior go in Template? Template for one thing lists the AOE of the effect sizes. Bounce does have that in its final explosion area. What about laser? That's a "line" type template. It could be bounce is just a different template type that has both aoe > 1 and target style "bounce."

At the moment, we have a BounceShoot action. Does that get subsumed by this Ability action? It could, but there will end up being a bunch of custom exceptions for bounce.

Effect will be quite a broad set of effects. It could include status effects, heal effects, damage, spawners, etc. We'll be constantly expanding this.

Implementation plan. We'll start with rebuilding the basic "Shoot" action as inheriting from an item. That means all the components: range, cost, effect, damage, template. Then the "ItemAbility" action to tie it all together.

In progress notes:

- fix damage action; abstract it to "ApplyActorEffect"
- (done) attach template to mouse
- (done) support spawn effects
- (done) add inventory to player, prepopulate it
- (done) add "Active" component, query the inventory to modify it
   - (done) has an initial condition problem; how do we get the first one active?
   -
- (done) check on line
- (done) check on wedge
- (done) check on circle
- (done) build spawnactor effect options
- (done) implement ammo costs (testing available)
- (done) implement ammo usage
- (done) implement ammostacks
- (done) implement reload?
- test non-ammo costs (health?)
- (done) make a weapon switching basic option
- make energy + costs
- (this is somewhat interesting?) make cooldown + system
- does this open interesting design space? not exactly ...
- do enemies need it to manage their decisions well? possibly.
- let's go back over to enemies and then see if cooldowns are a useful mechanism for spacing out their behavior.
- (done) make template return range-appropriate options
- (done) adjust the itemability action to be relative positions throughout so that pushing a bot will cause it to continue to shoot the same direction
   - this will require changes in the player
- test other weapons with different templates?
- (done) build reload behaviors?
- (~kinda) build move-and-shoot AI?
   - not sure how this would function, though

- bring back weapon animations

1. Grenade Launcher
1. Laser
1. Pistol
1. Rocket Launcher
1. Shotgun
1. Melee
   a. Cyclone was maybe too good?? Fun for enemies to cause mistakes.

## Notes on Bouncing/Grenade Implementation

1. (DONE) Bouncing grenade [Jay]
   - how would this work? mouse selects angle only, not distance, have a bounce rules engine.
   - then animate through the path that comes out of the rules engine
   - explode at the end. not that bad.
   - now the Q is whether to
   - okay we have the path. now, what is the right action design?
      - we need the path for animation purposes
      - but also the path should stop early if it hits something.
         - BUT we may not KNOW that it's going to hit something visually because it's in the fog.
   - so I think the rules engine can calculate explosion.
   - it returns the path with an "explode" flag on a move step that it should explode on.
   - in the preview mode that will show up visually
      - we will later need to filter out cases when you can't see bounce tiles
   - then the action will take the angle, direction, etc.
   - get its own rules read. and then trigger a sequence of animations (or a single custom animation? tbd) between the bounces. if it hits an explode then it triggers explode at that point. otherwise it just animates and explodes on the last point.

## Weapon Properties

1. Damage Types
1. Ammo

- usage
- type

1. Range (min, max, ...ground?)
1. Template
1. Appearance?
1. Maybe "status" is separate from characteristics? like you want current ammo load to be distinct?
1. Reload
1. Size/Weight?

## Damage Types?

Elemental damage is an option here, especially re: gas.

Also: armor-pen, push-pen, shield-pen?

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

First, NODES. - move - shoot - target (apply shoot intent?) - reload - flee - hunt

The most basic BT is just a root note that calls move every turn and move picks randomly.

Stretch: multiple enemies with relations that choose together.
so we could have a leader type which picks destinations and broadcasts them?
and then follower types that have a vector relative to the leader that they try to maintain.
for this to be really cool, we'd want it to be relative to leader movement direction, i.e -2, -2 relative to facing.
so do to do this - build facing, updated on each move - use waypoint system for leader as is - followers find the nearest leader on spawn and trail it?
how do followers know which spots are open? - we're back in a distributed systems problem. - well atually the leader just keeps a list of available slots and assigns on follower spawn - now mechanically how does this work. FindLeader behavior. - a component on leaders that manages open slots - what if leader moves after a follower? it's okay.
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

## On Death

Make a component that makes things happen on death. SpawnActorsOnDeath is the most straightforward.

This was easy. Done.

# Moves

Prototyped the dash mechanic, no cooldown. It's okay for now. It needs a complete refactor though. There's this emerging pattern that there need to be decision engines that decide what moves are valid, and then they feed both the UI and the internal destination logic. It's too distributed right now. In one place we need to take the player's position, and the world, and return valid destination tiles for each of the valid vector inputs.

Also, consider starting to rebuild the animation for moving multiple tiles so it stops in the intermediate tiles. Shouldn't be too bad.

Consider learning how mixins work, or some other way entirely to modularize this. It's totally entwined now in weird ways. I'm not sure if this is the feature to figure this out for, but maybe.

DONE -- consider the structural refactor. It'll be a good learning exercise. Then, go to enemies.

As for the flashing... I'm truly at a loss. It may just be something hacky like queing the update into the next draw frame so we skip one while the camera moves and then settle in at the new location?

TODO -- integrate a smoothly updating camera. That will be huge. Probably will inherit this from the prism devs over the coming days, so don't do too much exploration there now.

# Smooth Camera Thinking

So right now, display keeps a list of cells. Cells represent the spots in the display that are in screen coordinates. So cell (0,0) is the upper left cell when rendering.

[DELAY UNTIL IMMEDIATE MODE IN PRISM]

# Intents

The design concept here is that NPCs should declare their intents a turn in advance. Then, act on them.

This is straightforward to do if you are willing to wait a turn. In `act` you consume the moveintent and return the action it implies and move on.

The problem is that we want to ALSO set the next intent smoothly. Which needs information from the action to inform.

(Note: Intents are always expressed relative. So we're not moving to a target, we're moving to a point relative to our current location. Or shooting at a point relative to our location.)

Another problem. I want to

What are our options here?

1. We could queue up the action and accept that our planning for the following turn is going to be questionable. In the rocket case, this is totally fine.
   a. In the robot following case, it might be a little weird? But maybe it's okay? Let's try I guess.

Advice from Discord: Store "nextAction" on all the controllers.

At the end of a controller, swap

# Medium Term Thinking

I want to get this in the hands of people to learn about the core ideas around intents, how your movement triggers other turns, and some of the system at play are legible to players.

Questions:

- How do communicate when the player's actions will trigger a move? Right now it's click to cause a move. In many other tactics games it's "end turn." This is a weird variant. Will that track for a tactics player?
- Can I get intents to be understandable?
   - cases like: when I push an enemy, what will happen to their attack?
     (it may be that pushes need to interrupt attacks because it's pretty unpredictable)
- Turn outcome predictions; can I get players to understand them?
- Can players figure out how to interact with enemies to get things?
   - push them into walls?
   - push into gas clouds?
   - push into an enemy that's preparing to shoot
- a training challenge could be "what can you do without a weapon?

- does BUMP do anything? that could be cool actually. melee is not a click, it's a bump. (but how would predict happen? do you pre-predict the bumps in various directions? that could be a thing to test)

- there's something about how runner worked where they fired IFF you were in the target area.
   - may want to play with that here at some point. these are more like 'looking' intents rather than actual firing intents.
   - this removes the interplay between firing and environment though.

   - how do we think about vision ranges? that was not historically a thing. I could do it with mouseover. or "hold alt to see ranges"

TO BUILD:

- (next) predictable enemies. patrol in a rectangle?
   - 180 on collision predicted
   - (done) 90 CW/CCW on collision predicted
      - coul be smarter and rotate until an open space
   - move every-other-turn inch-worm guy?
   - faster guy?
   - nav point mover?
- TO THINK ABOUT: A laser "trip" wire -- emitted from one side. How is that different from the runner model or the intent shoot
   - we may want to just skip the "shoot at nothing" laser animation, that gets us functionally the same thing.
   - we would need a "move and use" action that does both as a single wrapped decision. could do it fancy with a behavior that sets the move and sets the shoot on the controller and then move-and-shoot combines them into one if both are set, otherwise sets just that one.
- an enemy that just shoots a grenade every other turn.
- (ish) health viz + prediction
   - need to try out the desaturated health bar style, instead of animation
      - how does this work exactly? so given the before and after, it's
        not that the symbols are changing. The symbols are set by the "before" damage. We actually use the same symbol, the half-width, for all characters. Then we have two cases: if it's the "base" color, and it's remainder 1, then
      - what is the data structure? it's fg and bg colors for each of four.
      - how would this extend to more granular custom bar? we would be adjusting the glyph selection for the right most one, always, and the left-most remainder glyph. but otherwise the same.
   - (done) build it for enemy shoot intents
      - this will require bundling the damage across all sources
      - which I wanted to do anyway for the hitting a wall case
      - but it will require some deeper thinking
      - in the intent case, it's not too bad. We cycle all intents, accumulate damage per actor, and then display that.
      - in the "hit a wall" case we have to do some sort of delaying action. In "Push" we have to ask "will this damage the pushed entity?" before calling the action and have some flag that says "don't damage" and instead link it with the effect damage.
      - how would gas
   -
- web builds
- some sort of basic level to explore
- pickup? so you can walk over a gun or other item and get a new capability?
   - not a requirement; we'll just manage this all in the tutorial system
- (needs thinking) some sort of dialog system?? how do I tell people what is going on?
   - needs a dialog UI thing
   - needs a way to manage the world into particular state
   - reseting when something fails
- I could build o
- this COULD be where the fancier movement system is intersting to try. Can I make a fun "parkour" type course?
   - this could be a fun intermediate thing to build. it's compact
- BROADLY we need to
- make the shift-roll instant?

DONE -- propagate the damage collapse into the prediction phase, not just the application phase.

# TUTORIAL

What topics do we cover?

Movement Basics (no dash)

- go from A to B.
- "visit these spaces" ? then door unlocks
   - I could either test the actual button being pressed
- what do we want the to learn? that the world advances on movement.
- so we need something the player can see that's moving. Maybe it's just a 180 bounce robot that is patrolling the area "outside?"
   - like a room with a glass boundary and bots patrolling outside.
- do we have an "interact" button? in the past we had "bump" door but so far that's not in the game
- so, no.
- after you move successfully to a few "target" points, transition out.
  Movement (BLINK)
- a "laser" that toggles on and off in a doorway, so you have to learn "wait" to time it right?
   - this is better as a "roll" effect actually.
- [TODO] some energy or cooldown system. try CD first. - [TODO] build CD system I guess
  Pushing
- Some sort of melee attack? Bump??
- what threat is there to you? one-on-one you just win, probably, if you have a 1 damage melee with 2 push.
- but that's okay. if you learned about positioning them into walls, that's cool.
- then you give people a gun.
- [THINK] push needs to remove movement intent, I think -- otherwise they just move right back again which feels weird.
- this teaches "KILL" indicator.
   - [THINK] which we may want to move down into the actual actor space instead of above?
- 1v1 bump melee
- 1v2 bump melee
- 1v4 bump melee

Ranged

- give a pistol
- give a shotgun
- reach reload
   - [DONE] reload animation messages
   - [DONE] give people infinite ammo

environmental

- put barrels in the space - ramp up difficulty`

Intents

- how to teach "wait"? -- delay this until combat. it's about manipulating space more. let someone walk toward you then you bop them

Development Sequence: - [DONE] Prefab loading - [DONE] Make a basic room. - [DONE] Simple system that reacts to movements - [DONE] transition between prefabs or reloads. - [DONE] A dialog system on screen. (put it on top, move the other UI elements to the bottom.) - [DONE] triggers? currently it's "space" but it could be "move to these places" or "press these keys." - for now, it's "go to these places." that's repeatable.
[DONE] need a "lit up" cell component? start a pulsing (sin) animation for it. Do I make this random? for now, yes. This is a little odd; the animation needs to start when the animation is added. I guess we do that in tutorialsystem. - The dialog is feeling weird. I think we gotta lock controls for the first few. - after N of these, trigger a world reload
[DONE] message from tutorial to playstate to reload
[DONE] reload in playstate, re-adding a player.
[DONE] make tutorial player adding different? TBD.
[DONE] make the next section - [TODO] make option for dialog undismissable

What is the combat scenario?

[TODO] Melee scenario. Requires a melee weapon implementation (lol). But one idea here is to have it be the 3 spaces in front of you, which depend on last move facing. Click to use. Could be cool.

[DONE]Combat drones. First, un-armed. Do they just wander? Or come at you? Do they do damage? The most simple model is they path to player with perfect information and if they get close to you do an AOE burst attack.
   This is having trouble because targeting wants to aim "away" from the bot.
   Where to fix this? Shoot BEHAVIOR should fire if it can hit the enemy.
If we

How are we going to handle these progressive encounters?
   - [DONE] if you die on any of them, reset to the start of ... that one?
   - [DONE] if that's the case, each needs their own step. let the map be the same for convenience, but then have separate
   - [DONE] need an "actor removed" listener to catch both bot deaths and player death (reset)

Next scenario?
   - what to teach?
      - evading ranged attacks?
      - you need to push
      - you need dash to setup attacks
   - complexity to Add
    - [DONE] reload requirements
    - [TODO] dash cooldown
      - do I do this as energy cost? that's more flexible
      -

Other todos
   - [DONE] make a scenario where you can only push into walls to kill?
      - consider making enemies higher health
   - [TODO] make a scenario with ranged combat
      - this is the "final act" -- both kinds of enemies, stronger enemies, but still just a pistol.
   - [DONE] make the HP indicator more prominent
   - [DONE] make the weapon "clip" tracker more visual

   - [DONE] Try removing move intent on push.
   - [DONE] Make "reload" indicator on character
   - [DONE] Make "EMPTY" follow the player's cursor
   - [DONE] remove burst attack, in favor of a direct damage attack if the player doesn't move.
      - challenge is that then it's nearly impossible for the player to take damage. but that's maybe okay.
      - could also just be a small angle attack around the attack. a mini burst.
   - [DONE] remove ability to shoot through walls
   - [DONE] if oyu mouse over an enemy out of your range it still simulates effects
   - [TODO] sometimes burst bots don't attack properly
   - when scenes get busy it's very hard to tell which bot is doing which thing.
      - and then the sequence of enemy movements becomes important
      - this is too precise
   - [DONE] if the target environment changes between the source and the target, canPerform can fail and then the shot doesn't happen.
      - so the issue here is that we are overloading Ability.canPerform with both "should I shoot at this" and executing the shot itself.
      - I think conceptually there's, like:
         "can I fire" which is (costLegal and cooldownLegal)
         "good target for me" which is (can see, canPathStraightTo, rangeLegal)
      - then when we fire, we only care about "can I fire." If the direction is locked in, do it.
      - THEN the actual performance needs to be somewhat more complex. it needs to figure out the "actual" destination now. so, move through the path to target and return a final actual destination given the situation on the ground now.
   - [DONE] sometimes the melee bots don't attack when in range, what's up with that
   - [TODO] title screen
   - [TODO] look into laser -- shouldn't template stop when it hits an impassable? (this is not fatal; not shipping laser)
   - [TODO] try to balance it some more??

Do it with the pistol scenario first. We can always move it around later to be melee when that is built.

[TODO] Screen shake? Damage indicator?
[DONE] Final combat encounter with ramping difficulty
   - add ranged attackers
   - make the melee attackers have more health

It's not feeling fun. A few things to try:
  - [DONE] Remove friendly fire; make it so at range they only fire if you're in their sights.
   - [DONE] Add a component that makes this conditional; some weapons should not work this way. My current thinking is that "instant" weapons are "tracking" and only fire if target in sight but projectile weapons (grenades, rocket, missile, etc.) are a commitment to shoot regardless. This means you may still trigger friendly fire, but you have to actually be in range. (This may be a case to switch the enemies to projectile so it hits the first thing it sees. That's complex with the latest targeting code.)
   - Now the issue is they simply retarget immediately. There's gotta be something behavioral here; if you failed to shoot, you can't try to shoot again next turn? What's the mechanism? Component or blackboard? Let's try blackboard. In turn handler?
- [TODO] melee weapon for conservation?
- [DONE] highlight cells from targeted person
   - first order this is straightforward but with larger target areas from non-pistol weapons, this gets tricky. we may want that functionality only when no weapon is selected, i.e. an "inspect" mode
   - mark a "selected actor" field with BehavioralController
   - when rendering intents, darken non-selected actor sources
   - [TODO] the next layer challenge here is overlapping targets. it needs to light up for all of them. This is the same shape issue as "multiple actors targeting the same tile should light it up MORE" problem; could solve in same way.
- [TODO] ration ammo
   - [TODO] build ammo pickup on entering the cell
   - [TODO] have it drop from enemies
- [TODO] add more explosive barrels

## SECOND GEN

We've got SOMETHING working but it's not yet clicking for players. In this next round we want to increase the complexity and diversity of play. Mostly this is about getting to a point where we can mix and match more features together.

This has three sections: new enemies, new weapons, new engine capabilities.

Capabilities:
 - multi-turn reload
 - misfire chance on weapons
 - jam chance on weapons
 - mouse-over info viewer
 - show multiple weapons
 - abstract the interrupt ability into a weapon component

Weapons:
 - concussion grenade (big push, likely stuns? do we only stun if you hit something?)
 - emp grenade (no push, guaranteed interrupt)
 - poison grenade
 - smoke grenade?

Enemies:
 - grenadier (just infinitely shoots grenades?)
   - what is the counter-play here? you have to have energy available?
 - shotgunner with lots of health
 - mine layer (drops a bomb entity)
   - adapt path finding for enemies to avoid mines
 - explody-bots that run at you and go boom, self-destructing
   - (what is hard about this? it creates urgency. they would also need to just boom during movement, not only triggering after detection.)
 - npcs
   - worm that moves every other turn
   -



# PREDICTION

This is a whole quagmire. How deep do we go? There can be effect chains like: rocket activates before an enemy and pushes the player out of the way before an enemy hits. So "true" full prediction of the next turn is challenging.

One limiting constraint might be to say "the goal of prediction is to predict first order intents, not second order." So we should predict that an enemy gets pushed by your shotgun but not that the rocket then hits them and pushes them back into range of you.

We might also mitigate this by not giving "chain" type effects to enemies. So, rarely give enemies a push. And maybe don't give the PLAYER time delayed effects other than mines or whatever. No shooting missiles that tend to push into second order prediction territory. Maybe no missiles at all, actually. TBD.

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
1. (done) Gas emitters
1. Reimplement guns? (this is a big thing)
1. (DONE) Go back to enemies, and learn behavior trees. (curious about this but I need more actions for them to take than pure movement. might need shoot actions. or maybe it's enough to do a kind of patrol / search / attack loop of some kind?? )
1. Consider making an action for Gas getting removed, because there may be some relevant shared logic there eventually?
1. (DONE) Make Damage action, which could turn into fire damage making walls get scorched or doors failing open.
1. (DONE) Consider making double-wide doors that open/close together. I think using some sort of relationship method??
1. Start a light UI framework.
   a. Requires getting overlay to work in screen coordinates.
   b. (and to simultaneously handle world coordinate draws as well??)
   c. Some simple object structure that lets me write UI things with useful screen coordinates and access to the level for updates.
1. (NOT DOING) Make the gas objects into a real object.
1. (DONE) Add a natural gas one?? No damage, can be lit on fire.
1. (done) Make the gas generator objects: (this does need something to trigger it ... so we need a damage application UI first)
   a. fuel line that spurts gas for N turns
   b. canisters of different types
   c. weapons that generate smoke / fire?
   d. strange machines that just puff poison or fuel or smoke?
1. (DONE) Fix animations being visible when actor not visible to the player.
   a. This is in progress on hide-animations-when-not-seen-by-player branch. But not working.
1. Find a better 8x16 font?
1. Border around the "speech" bubbles?
1. Start designing the weapon component systems? Much more modular. Damage, Range, Template, Ammo, etc.
   a. I think for the emitters/environment stuff to be interesting at minimum I need click-to-do-damage. That doesn't need the whole system, though. I could just do click to damage for now.
1. (AFTER) Rebuild push prediction system.
   a. Start with a rules engine. The question is push amount, vector.
   b. Then you return a table with positions, and if a push failed due to collision, return a position with a flag saying "collided"
   c. Then in render layer ... we're not triggering an animation, so what is it? I guess it's related to the mouseover state, and then if we're in that state do a special look for actors with a Pushing component. IF present, pull the data out and render it.
   d. The render is like a "•" for transit spots, and then the drawable grayed out.
   e. If there's impact damage maybe put that on the tile getting colided with.
1. (done) Rebuild push animation system.
1. (done) Build a grenade type weapon?
1. (NEXT) Build a basic "shot" animation to help communicate what's happening in current demo videos. This is super simple.
1. (DONE) Build a rocket -- has a destination but takes some turns to get there and can be intercepted and maybe shot?? or pushed??
   a. This is intriguing. So it's an actor, with a smoke emitter, facing, and a special controller. It's spawned at a location and locks in a path and is on that path moving ... N a turn.
   b. for testing, just lock onto the player.
   c. maybe it accelerates?
   d. could visualize its target somehow? we're going to want a targeting layer.
   e. when it gets within 1 space of the target, explode? make fire all around you? (will need to adapt the spawnactorsondeath to accept multiples) or just do damage to anyone nearby. leave light smoke behind.
   f. Could do it as a new 'explode' action to encapsulate it.
1. (DONE) Try using TextMove to make a little smoke "puff" out of a machine?
1. (DONE) Check in on gasDiffusion and what to do if it tries to diffuse into a wall in gasEmitter logic.
1. Separate out Impermeable as "can't spread" versus a new "armor" damage management system. You can have armor to N damage types: push, kinetic, laser, fire, poison, etc.
1. (DONE) Fix the fact you can dash through walls. [jay]
1. (NEXT) Intent system?
   a. How does this work? Shift everything back a turn? First in the controller we consume any intents that are set.
   b. Could be a MoveIntent or a ShootIntent. If there are no intents set (OR you just consumed an intent) then set a new one.
   c. Have some visualization system for intents.
   d. This is a big rewrite of the botcontroller systems. Worth doing sooner rather than later.
   e. Am I convinced this is a good approach? I liked it for shooting, quite a bit. It is well trod territory in games I like.
   f. Do I learn anything by building it?
   g. Well, I want to build it for shooting regardless. Might as well.
1. (DONE) Make it so you can push the rocket. At the moment it goes to the next path immediately. It needs to sense that it's been pushed off course and then recalculate.
1. (FIXED) Something still infinite looping on rocket explotions.
1. (FIXED) Make rockets successfully blow each other up
1. (DONE) Pipe, Gas, etc. shows push [jay]
   a. What might I do that inherits for this? Immovable is one. That's not linguistically correct for Gas. Which is ephemeral? Or
1. (BUG) Can push rockets out of the world, over walls?
1. Try other move systems? Rebuild the old style? Consider some runner-style moves? Like optimize certain movement reactively with environment. Versus using the moves directly. See how that feels?
1. Mines as weapons, grenades, stasis traps, ... ?
1. Overwatch -- pick a spot and anyone who crosses it gets shot [Jay]
1. Sensor pulse ability [Jay]
1. Stun effect [Jay]
1. [BUG] (0,0) or (1,1) is shown as a move option if a diretion is totally blocked.
1. Could do more enemy design
   - a lot of this will have to do with weapons and abilities, so better to wait. I know I have the fundamental architecture stuff settled and intents work fine.
1. (done) Build out weapon system.
   - I know I need this, could start now. I won't learn anything but it is part of the future regardless so ... might as well.
1. Go hard on movement.
   - Treat the rules system as a collection of tests -- what is the "best" move I could do in each of the four cardinal directions based on the environment?
   - This loses a bit of flavor ... I could "say" the name as you wall run? Have a notice appear saying it's back again?
   - Think about CD versus energy.
   - Do we get rd of the running/jumping distinction? All that really used that was "running jump."
   - Do we have other environmental movement ideas?
      - is there a "hide"? like in a doorway?? lifts you up in the air and stuff can walk under you?
      - some sort of "wrap" around a one tile wall? a swing?? ..@#d
      - something that gets you "double diagonal" move ... not sure what would trigger it tho.
      - stuff that's extra environmentally aware, like a mantle over "low" items?
         - enter vents?
      - grab a bot and move it somehow?
      - there's enemy jump of course
      - "pop smoke" and move somehow? or is that just two capabilities
      - the general give is that this would be a quite restrictive item. Or maybe you can break it up. but it really changes playstyle. maybe this is like the "light" loadout style gets this, but others don't.
   - does the implementation teach us anything? we could do some play testing I guess. but if you're not pressured will it feel like anything?
   - of course there's the "teleport dash" approach
      - I found this didn't quite click with people.
   - is this ... easy to do? to start with its: wall run, wall jump, hop.
      - burrow would NOT use this system beacuse it requires some deeper work.
      - so in practice it's not that many moves. Might be fun.
1. Smoke LOS update (allow for semi-opacity)
1. Return to the asset pipeline with new tools?
1. Consider options for health visualization + especially showing damage effects in prediction mode.
1. More complex bot behaviors?
1. More NPC "chatter" to explain their behaviors?
1. [Done] Blend background colors versus overwriting.
1. More color methods. Saturation, hue shift, etc.