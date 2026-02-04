AMMO_TYPES = {}

local function registerAmmo(type)
   local constructor = function(count)
      return prism.Actor.fromComponents {
         prism.components.Name(type),
         prism.components.Drawable { index = 241, color = prism.Color4.YELLOW },
         prism.components.Item({
            stackable = type,
            stackCount = count or 1,
            stackLimit = 1000
         })
      }
   end

   prism.registerActor("Ammo" .. type, constructor)
   --- @return Actor
   return constructor
end

-- table stores ACTOR constructors that we can pass into Item.stackable
AMMO_TYPES["Pistol"] = registerAmmo("Pistol")
AMMO_TYPES["Rocket"] = registerAmmo("Rocket")
AMMO_TYPES["Shotgun"] = registerAmmo("Shotgun")
AMMO_TYPES["Laser"] = registerAmmo("Laser")
AMMO_TYPES["Rifle"] = registerAmmo("Rifle")
AMMO_TYPES["PoisonGrenade"] = registerAmmo("PoisonGrenade")
