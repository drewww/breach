local ItemPanel = Panel:extend("ItemPanel")

function ItemPanel:__new(display, pos, worldDisplay)
   self.super.__new(self, display, pos)
   self.worldDisplay = worldDisplay
end

function ItemPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if not player then return end

   local playerComp = player:get(prism.components.Player)
   local consumeProgress = playerComp and playerComp.consumeHoldProgress or 0

   if player:has(prism.components.Slots) and player:has(prism.components.Inventory) then
      local slots = player:get(prism.components.Slots)
      local inventory = player:get(prism.components.Inventory)

      local xOffset = 0
      local yOffset = 1
      local width = 14

      for i, item, type in slots:iter() do
         yOffset = 1

         self.display:print(xOffset, yOffset - 1, " " .. tostring(i) .. " ", prism.Color4.BLACK, prism.Color4.ORANGE)

         if item then
            local isActive = slots.active == i
            local itemName = item:getName()

            yOffset = isActive and -1 or 1

            self.display:print(xOffset, yOffset - 1, " " .. tostring(i) .. " ", prism.Color4.BLACK, prism.Color4.ORANGE)

            -- Determine background color
            local bgColor = C.UI_BACKGROUND
            -- if isActive then
            --    bgColor = prism.Color4.DARKGREY:lerp(prism.Color4.WHITE, 0.1)
            -- end
            self.display:rectangle("fill", xOffset, yOffset, width - 1, 6, "", prism.Color4.TRANSPARENT, bgColor)

            -- Print item name
            self.display:print(xOffset, yOffset, itemName, prism.Color4.WHITE, bgColor)

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

               self.display:print(xOffset, yOffset + 4,
                  "USES " .. tostring(current),
                  prism.Color4.WHITE, bgColor)
            end

            -- Calculate the width of this item's section before drawing anything
            local itemSectionWidth = width

            -- Draw ammo/stack bars
            -- if max > 0 then
            --    for i = 1, max do
            --       local color = i % 2 == 0 and countColor or countColor:lerp(prism.Color4.BLACK, 0.1)

            --       if i > current and not consumeable.stackable then
            --          color = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
            --       end

            --       self.display:rectangle("fill", xOffset + i - 1, 1, 1, 2, " ", prism.Color4.TRANSPARENT, color)
            --    end
            -- end

            -- Display ammo reserves for this weapon, right-justified within its section
            if clip then
               local ammoStack = inventory:getStack(clip.type)

               if ammoStack then
                  local ammoItem = ammoStack:get(prism.components.Item)
                  if ammoItem then
                     local ammoLabel = "ammo"
                     local ammoCount = tostring(ammoItem.stackCount)
                     local maxAmmoWidth = math.max(#ammoLabel, #ammoCount)

                     -- Calculate right-justified position within this item's section
                     local rightX = xOffset

                     -- Print ammo count below, right-aligned
                     local countX = rightX + maxAmmoWidth - #ammoCount
                     self.display:print(xOffset, yOffset + 4,
                        "AMMO",
                        prism.Color4.WHITE, bgColor)
                     self.display:print(xOffset, yOffset + 5,
                        tostring(current) .. "/" .. tostring(max) .. " (" .. tostring(ammoCount) .. ")",
                        prism.Color4.WHITE, bgColor)
                  end
               end
            end

            -- make a cuthrough box for the icon

            local drawable = item:expect(prism.components.Drawable)
            local iconX, iconY = xOffset + 4, yOffset + 2

            -- self.worldDisplay:putDrawable(math.floor((iconX + self.pos.x) / 4), math.floor((iconY + self.pos.y) / 2),
            --    drawable,
            --    prism.Color4.WHITE, 200)
            --
            --
            self.worldDisplay:rectangle("fill", math.floor(iconX / 4) + 5, math.floor((iconY) / 2) + 22, 5, 1, " ",
               prism.Color4.TRANSPARENT, prism.Color4.BLACK)


            self.worldDisplay:putDrawable(math.floor((iconX) / 4 + 0.5) + 6, math.floor((iconY) / 2) + 22,
               drawable,
               prism.Color4.WHITE, 200)


            self.display:rectangle("fill", iconX - 2, iconY, 8, 2, " ", prism.Color4.WHITE,
               prism.Color4.TRANSPARENT)
            --
            -- render the drop/consume buttons here
            if isActive then
               self.display:print(xOffset, yOffset + 6, " f ", prism.Color4.BLACK, prism.Color4.ORANGE)
               self.display:print(xOffset + 4, yOffset + 6, "drop", prism.Color4.ORANGE, prism.Color4.BLACK)

               -- Draw consume button with progress indicator
               local fullText = " g  extract    "
               local totalChars = #fullText

               -- Calculate how many characters should be filled based on progress (0 to totalChars)
               local filledChars = consumeProgress * totalChars

               -- Print each character with the appropriate background
               for i = 1, totalChars do
                  local char = fullText:sub(i, i)
                  local charX = xOffset + i - 1

                  -- Determine background color based on whether this position is filled
                  local bgColor, fgColor
                  if i <= filledChars then
                     fgColor = prism.Color4.BLACK
                     bgColor = prism.Color4.ORANGE
                  else
                     fgColor = prism.Color4.ORANGE
                     bgColor = prism.Color4.BLACK
                  end

                  -- First character "g" is always the key indicator with ORANGE background
                  if i <= 3 then
                     self.display:print(charX, yOffset + 7, char, prism.Color4.BLACK, prism.Color4.ORANGE)
                  else
                     self.display:print(charX, yOffset + 7, char, fgColor, bgColor)
                  end
               end
            end
         end


         -- Move offset to next item section
         -- this is fixed width now -- to address
         xOffset = xOffset + width + 1
      end
   end



   self.super.cleanupPut(self)
end

return ItemPanel
