local ReloadTarget = prism.targets.InventoryTarget(prism.components.Ability, prism.components.Clip)


---@class Reload : Action
local Reload = prism.Action:extend("Reload")

Reload.targets = { ReloadTarget }
Reload.requiredComponents = { prism.components.Inventory }

function Reload:canPerform(level, item)
   local clip = item:expect(prism.components.Clip)
   local ammo = self.owner:expect(prism.components.Inventory):getStack(AMMO_TYPES[clip.type])

   if ammo and ammo:expect(prism.components.Item).stackCount > 0 then
      return true
   else
      return false
   end
end

function Reload:perform(level, item)
   local clip = item:expect(prism.components.Clip)
   local ammo = self.owner:expect(prism.components.Inventory):getStack(AMMO_TYPES[clip.type])

   if ammo then
      local ammoItem = ammo:expect(prism.components.Item)
      local ammoDesired = clip.max - clip.ammo
      local ammoAvailable = ammoItem.stackCount
      local ammoToLoad = math.min(ammoDesired, ammoAvailable)

      clip.ammo = clip.ammo + ammoToLoad
      self.owner:expect(prism.components.Inventory):removeQuantity(ammo, ammoToLoad)
   end
end

return Reload
