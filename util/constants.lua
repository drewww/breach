SCREEN_WIDTH = 31
SCREEN_HEIGHT = 20

GAS_TYPES = {
   smoke = {
      factory = prism.actors.Smoke,
      keepRatio = 0.95,
      spreadRadio = 0.05 / 8,
      reduceRatio = 0.9,
      minimumVolume = 0.5,
      threshold = 2.0,
      fg = prism.Color4.TRANSPARENT,
      bgFull = prism.Color4.WHITE,
      bgFading = prism.Color4.GREY,
      spreadDamage = 0,
      scorchColor = nil,
      scorchIntensity = nil,
      cellDamage = 0
   },
   fire = {
      factory = prism.actors.Fire,
      keepRatio = 0.0,
      spreadRadio = 1.0 / 8,
      reduceRatio = 0.9,
      minimumVolume = 0.5,
      threshold = 1.0,
      fg = prism.Color4.TRANSPARENT,
      bgFull = prism.Color4.RED,
      bgFading = prism.Color4.YELLOW,
      spreadDamage = 0,
      scorchIntensity = 0.1,
      scorchColor = prism.Color4.DARKGREY,
      cellDamage = 5
   },
   poison = {
      factory = prism.actors.Poison,
      keepRatio = 0.0,
      spreadRadio = 1.00 / 8,
      reduceRatio = 0.99,
      minimumVolume = 0.5,
      threshold = 3.0,
      fg = prism.Color4.WHITE,
      bgFull = prism.Color4.LIME,
      bgFading = prism.Color4.GREEN,
      spreadDamage = 0,
      scorchColor = prism.Color4.LIME,
      scorchIntensity = 0.005,
      cellDamage = 1
   },
   fuel = {
      factory = prism.actors.Fuel,
      keepRatio = 0.9,
      spreadRadio = 0.1 / 8,
      reduceRatio = 0.998,
      minimumVolume = 0.5,
      threshold = 3.0,
      fg = prism.Color4.YELLOW,
      bgFull = prism.Color4.TRANSPARENT,
      bgFading = prism.Color4.TRANSPARENT,
      spreadDamage = 0,
      scorchColor = nil,
      scorchIntensity = nil,
      cellDamage = 0
   }
}
