local ItemPanel = Panel:extend("ItemPanel")

function ItemPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Inventory) then
      local activeItem = player:expect(prism.components.Inventory):query(prism.components.Ability,
         prism.components.Active):first()

      if not activeItem then return end

      local string = activeItem:getName()

      local clip = activeItem:get(prism.components.Clip)
      local consumeable = activeItem:get(prism.components.Item)
      if clip then
         string = string .. " " .. clip.ammo .. "/" .. clip.max
      elseif consumeable.stackable then
         string = string .. " (" .. tostring(consumeable.stackCount) .. ")"
      end

      if activeItem then
         self.display:print(1, 1, string, prism.Color4.WHITE,
            prism.Color4.DARKGREY)
      end
   end

   self.super.cleanupPut(self)
end

return ItemPanel
