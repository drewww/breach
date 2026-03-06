require "modules.game.animations.textanimations"

spectrum.Panel = require "modules.game.panel"
prism.registerRegistry("panels", spectrum.Panel, false, "spectrum")

prism.Collision.assignNextAvailableMovetype("walk")
prism.Collision.assignNextAvailableMovetype("fly")

prism.registerRegistry("turnhandlers", prism.TurnHandler)
