-- Flavor categories
local FlavorCategory = {
   MONEY = "money",
   WEAPON = "weapon",
   AMMO = "ammo",
   UTILITY = "utility",
   BURST_BOT = "BURST_BOT",
   CONTAINER = "container"
}

-- Flavor text database
local FLAVOR_TEXT = {
   [FlavorCategory.MONEY] = {},
   [FlavorCategory.WEAPON] = {},
   [FlavorCategory.AMMO] = {},
   [FlavorCategory.UTILITY] = {},
   [FlavorCategory.CONTAINER] = {},
   [FlavorCategory.BURST_BOT] = { "Burst bot flavor text that has enough text to need to wrap." }
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
      self.str = "Nothing remarkable."
   end
end

-- Export the category enum for use in other files
Flavor.Category = FlavorCategory

return Flavor
