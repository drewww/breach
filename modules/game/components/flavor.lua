-- Flavor categories
local FlavorCategory = {
   MONEY = "money",
   WEAPON = "weapon",
   AMMO = "ammo",
   UTILITY = "utility",
   CONTAINER = "container",
   BURST_BOT = "BURST_BOT",
   LASER_BOT = "LASER_BOT",
   BOOM_BOT = "BOOM_BOT",
   AMMO_STASH = "AMMO_STASH",
   WEAPON_STASH = "WEAPON_STASH",
   MONEY_STASH = "MONEY_STASH",
   PISTOL = "PISTOL",
   RIFLE = "RIFLE"
}

-- Flavor text database
local FLAVOR_TEXT = {
   [FlavorCategory.MONEY] = {},
   [FlavorCategory.WEAPON] = {},
   [FlavorCategory.AMMO] = {},
   [FlavorCategory.UTILITY] = {},
   [FlavorCategory.CONTAINER] = {},
   [FlavorCategory.LASER_BOT] = { "Somehow, the hangover from getting disconnected by a laser blast is the worst kind." },

   [FlavorCategory.BOOM_BOT] = { "Some asshole in the dorms made their alarm the sound these bots make when they sense you.", "SOP12.3.2 Shoot the scuttlers first. Always." },

   [FlavorCategory.BURST_BOT] = { "Designed to lift other workers, their scissor lifts have become remarkably strong melee weapons.", "<ACK MOVE ^7k9m-2x4p-6n8q @[12.3 139.0 6.0] TO [12.8 139.0 6.0] [14.1 139.0 3.0] [12.3, 139.0 1.0] RETURN>" },
   [FlavorCategory.AMMO_STASH] = { "In an open-carry district, the corps are mandated to make ammo available in their facilities." },
   [FlavorCategory.WEAPON_STASH] = { "If the bots carry their own weapons, who are these even for?" },
   [FlavorCategory.MONEY_STASH] = { "Why the corps pay so much for each others' emails has always been a mystery to me.", "Not much the ICE can do against stealing the bioRAM from the machines themselves." },
   [FlavorCategory.PISTOL] = { "Dull, grey, and loud.", "Armor-piercing bullets are a must; nothing else gets through the bots 'metal shells." },
   [FlavorCategory.RIFLE] = { "The recoil is tough on lighter frames, but the fire rate makes up for it." },

}

--- @class Flavor : Component
--- @field str string
local Flavor = prism.Component:extend("Flavor")
Flavor.name = "Flavor"

--- Creates a new Flavor component with random text from the specified category
--- @param category string The flavor category (use FlavorCategory enum)
function Flavor:__new(category)
   category = category or FlavorCategory.CONTAINER

   prism.logger.info("creating flavor: ", category, FLAVOR_TEXT[category])
   if not category then
      self.str = ""
      return
   end

   local flavorList = FLAVOR_TEXT[category]
   if flavorList and #flavorList > 0 then
      local index = math.random(1, #flavorList)
      self.str = flavorList[index]
   else
      self.str = ""
   end
end

-- Export the category enum for use in other files
Flavor.Category = FlavorCategory

return Flavor
