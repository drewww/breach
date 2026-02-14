C = {}

-- UI Backgrounds
C.UI_BACKGROUND = prism.Color4.DARKGREY:lerp(prism.Color4.BLACK, 0.4)

-- Intent Colors (Enemy/NPC Actions)
C.SHOOT_INTENT = prism.Color4.RED:lerp(prism.Color4.BLACK, 0.6)
C.SHOOT_INTENT_DARK = C.SHOOT_INTENT:lerp(prism.Color4.BLACK, 0.5)

C.MOVE_INTENT = prism.Color4.GREEN:lerp(prism.Color4.BLACK, 0.6)
C.MOVE_INTENT_DARK = C.MOVE_INTENT:lerp(prism.Color4.BLACK, 0.5)

C.TRIGGER_INTENT = prism.Color4.YELLOW:lerp(prism.Color4.BLACK, 0.6)
C.TRIGGER_INTENT_DARK = C.TRIGGER_INTENT:lerp(prism.Color4.BLACK, 0.5)

-- Player Ability Preview
C.DASH_DESTINATION = prism.Color4.BLUE
C.ABILITY_IMPACT = prism.Color4.BLUE:lerp(prism.Color4.BLACK, 0.5)

-- Push Mechanics
C.PUSH_VALID = prism.Color4.GREY
C.PUSH_PATH = prism.Color4.DARKGREY
C.PUSH_COLLISION = prism.Color4.RED

-- UI Messages
C.WARNING_FG = prism.Color4.BLACK
C.WARNING_BG = prism.Color4.YELLOW

-- UI Panel Bar Colors
C.HEALTH_BAR = prism.Color4.RED
C.HEALTH_BAR_ALT = prism.Color4.RED:lerp(prism.Color4.BLACK, 0.1)

C.ENERGY_BAR = prism.Color4.BLUE
C.ENERGY_BAR_ALT = prism.Color4.BLUE:lerp(prism.Color4.BLACK, 0.1)

C.AMMO_BAR = prism.Color4.YELLOW
C.AMMO_BAR_ALT = prism.Color4.YELLOW:lerp(prism.Color4.BLACK, 0.1)

C.STACKABLE_BAR = prism.Color4.ORANGE
C.STACKABLE_BAR_ALT = prism.Color4.ORANGE:lerp(prism.Color4.BLACK, 0.1)

C.EMPTY_BAR = prism.Color4.GREY
C.EMPTY_BAR_ALT = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.1)
C.EMPTY_BAR_DEPLETED = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)

-- UI Panel Text Colors
C.TEXT_NORMAL = prism.Color4.WHITE
C.TEXT_INACTIVE = prism.Color4.GREY
C.TEXT_HEADER = prism.Color4.YELLOW

-- Health Bar Split Tile Colors (for helpers.lua)
C.HEALTH_FULL = prism.Color4.RED
C.HEALTH_DAMAGE = prism.Color4.PINK
C.HEALTH_EMPTY = prism.Color4.DARKGREY
C.HEALTH_DEAD_FG = prism.Color4.WHITE
C.HEALTH_DEAD_BG = prism.Color4.RED

-- Animation Colors
C.ANIM_EXPLOSION = prism.Color4.YELLOW
C.ANIM_MISS_FG = prism.Color4.BLACK
C.ANIM_MISS_BG = prism.Color4.RED
C.ANIM_CRIT_FG = prism.Color4.BLACK
C.ANIM_CRIT_BG = prism.Color4.LIME
