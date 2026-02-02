local ItemPanel = Panel:extend("ItemPanel")

function ItemPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Inventory) then
      local inventory = player:expect(prism.components.Inventory)
      local items = inventory:query(prism.components.Ability):gather()

      if not items or #items == 0 then return end

      -- Sort items by name for consistent ordering
      table.sort(items, function(a, b)
         return a:getName() < b:getName()
      end)

      local xOffset = 0

      for _, item in ipairs(items) do
         local isActive = item:has(prism.components.Active)
         local itemName = item:getName()
         local nameWidth = #itemName

         -- Determine background color
         local bgColor = C.UI_BACKGROUND
         if isActive then
            bgColor = prism.Color4.DARKGREY:lerp(prism.Color4.WHITE, 0.1)
         end
         self.display:rectangle("fill", xOffset, 0, nameWidth, 4, "", prism.Color4.TRANSPARENT, bgColor)

         -- Print item name
         self.display:print(xOffset, 0, itemName, prism.Color4.WHITE, bgColor)

         -- Get ammo/stack info
         local clip = item:get(prism.components.Clip)
         local consumeable = item:get(prism.components.Item)

         local countColor = prism.Color4.YELLOW
         local current, max = 0, 0
         if clip then
            current, max = clip.ammo, clip.max
         elseif consumeable and consumeable.stackable then
            current, max = consumeable.stackCount, consumeable.stackCount

            countColor = prism.Color4.ORANGE
         end

         -- Draw ammo/stack bars
         if max > 0 then
            for i = 1, max do
               local color = i % 2 == 0 and countColor or countColor:lerp(prism.Color4.BLACK, 0.1)

               if i > current and not consumeable.stackable then
                  color = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
               end

               self.display:rectangle("fill", xOffset + i - 1, 1, 1, 2, " ", prism.Color4.TRANSPARENT, color)
            end

            -- Move offset by the max of name width or bar width
            xOffset = xOffset + math.max(nameWidth, max) + 1
         else
            -- No bars, just move by name width
            xOffset = xOffset + nameWidth + 1
         end
      end
   end

   self.super.cleanupPut(self)
end

return ItemPanel
