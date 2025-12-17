--- @class CostOptions
--- @field ammo? number Ammo used per use (default: 0)
--- @field ammoType? string Ammo type required (default: "")
--- @field hp? number Health cost per use (default: 0)
--- @field energy? number Energy cost per use (default: 0)

--- Represents the cost to use the ability.
--- @class Cost : Component
--- @field ammo number Ammo used per use.
--- @field ammoType string TODO figure out how to represent ammo types. This is a deeper project.
--- @field hp number Health cost per use.
--- @field energy number Energy cost per use.

local Cost = prism.Component:extend("Cost")
Cost.name = "Cost"

---@param options CostOptions
function Cost:__new(options)
   options = options or {}

   self.ammo = options.ammo or 0
   self.ammoType = options.ammoType or ""
   self.hp = options.hp or 0
   self.energy = options.energy or 0
end

--- Returns true if the item can be used `times`.
--- @param user Actor The actor using the item.
---@param item Actor The item.
---@param times integer The number of times to check that it's useable.
---@return boolean
function Cost.canUseMultiple(user, item, times)
   local multipleUses = true
   -- check if it has 2x the cost available in the clip OR stack
   local cost = item:expect(prism.components.Cost)
   local hp = user:get(prism.components.Health)
   local inventory = user:expect(prism.components.Inventory)
   local itemCount = item:expect(prism.components.Item).stackCount
   -- TODO energy
   -- TODO cooldown

   if cost.ammo then
      local clip = item:get(prism.components.Clip)

      if not clip and cost.ammo * times > itemCount then
         multipleUses = false
      end

      if clip and cost.ammo * times > clip.ammo then
         multipleUses = false
      end
   end

   -- TODO energy check
   -- TODO cooldown check
   return multipleUses
end

return Cost
