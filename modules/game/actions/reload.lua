local ReloadTarget = prism.targets.InventoryTarget(prism.components.Ability, prism.components.Clip)
local SuppressAnimation = prism.Target():isType("boolean")

---@class Reload : Action
local Reload = prism.Action:extend("Reload")

Reload.targets = { ReloadTarget, SuppressAnimation }
Reload.requiredComponents = { prism.components.Inventory }

function Reload:canPerform(level, item)
   local clip = item:expect(prism.components.Clip)
   local inventory = self.owner:expect(prism.components.Inventory)
   local ammo = inventory:getStack(clip.type)

   if ammo and ammo:expect(prism.components.Item).stackCount > 0 and clip.ammo < clip.max then
      prism.logger.info("can reload")
      return true
   else
      return false
   end
end

function Reload:perform(level, item, suppress)
   local clip = item:expect(prism.components.Clip)
   local ammo = self.owner:expect(prism.components.Inventory):getStack(clip.type)

   if ammo then
      local ammoItem = ammo:expect(prism.components.Item)
      local ammoDesired = clip.max - clip.ammo
      local ammoAvailable = ammoItem.stackCount
      local ammoToLoad = math.min(ammoDesired, ammoAvailable)

      clip.ammo = clip.ammo + ammoToLoad

      self.owner:expect(prism.components.Inventory):removeQuantity(ammo, ammoToLoad)

      prism.logger.info("reloaded: ", ammoToLoad, " remaining: ", ammoItem.stackCount, "in clip: ", clip.ammo)

      if not suppress then
         level:yield(prism.messages.OverlayAnimationMessage({
            animation = spectrum.animations.TextReveal(self.owner, "RELOADED", 0.1, 2.0, prism.Color4.BLACK,
               prism.Color4.YELLOW, { worldPos = true, actorOffset = prism.Vector2(1, -1) }),
            owner = self.owner,
            skippable = false,
            blocking = false
         }))
      end
   end
end

return Reload
