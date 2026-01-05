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
      -- if clip then
      --    string = string .. " " .. clip.ammo .. "/" .. clip.max
      -- elseif consumeable.stackable then
      --    string = string .. " (" .. tostring(consumeable.stackCount) .. ")"
      -- end

      if activeItem then
         self.display:print(0, 0, string, prism.Color4.WHITE,
            C.UI_BACKGROUND)

         local current, max = 0, 0
         if clip then
            current, max = clip.ammo, clip.max
         elseif consumeable.stackable then
            current, max = consumeable.stackCount, consumeable.stackCount
         end

         for i = 1, max do
            local color = i % 2 == 0 and prism.Color4.YELLOW or prism.Color4.YELLOW:lerp(prism.Color4.BLACK, 0.1)

            if i > current then
               color = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
            end

            self.display:rectangle("fill", i - 1, 1, 1, 2, " ", prism.Color4.TRANSPARENT, color)
         end
      end
   end

   self.super.cleanupPut(self)
end

return ItemPanel
