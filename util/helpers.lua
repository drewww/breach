--- Helper function to calculate health tile display data
--- @param healthValue number The current health value
--- @return (number|string)[] Array of characters/numbers for health tiles
local function calculateHealthTiles(healthValue)
   local tiles = {}

   if healthValue <= 0 then
      -- If dead or dying, show 4 'x' characters
      for i = 1, 4 do
         tiles[i] = 210
      end
      return tiles
   end

   -- Calculate health display tiles (max 8 health = 4 full tiles)
   local fullTiles = math.floor(healthValue / 2)
   local remainder = healthValue % 2

   local healthChars = { 222, 220 } -- indexed by health points (1-2)

   for i = 1, 4 do
      if i <= fullTiles then
         -- Full tile (220)
         tiles[i] = 220
      elseif i == fullTiles + 1 and remainder > 0 then
         -- Partial tile based on remainder (1-3 health points)
         tiles[i] = healthChars[remainder]
      else
         -- Empty space
         tiles[i] = " "
      end
   end

   return tiles
end

--- Helper function to calculate health bar display using 8-pixel tall tiles
--- @param beforeHealth number The health before damage
--- @param afterHealth number The health after damage
--- @param armor number? The armor strength (0-4)
--- @return table[] Array of tile data with index and fg color
local function calculateHealthBarTiles(beforeHealth, afterHealth, armor)
   local tiles = {}

   -- prism.logger.info("health: ", beforeHealth, afterHealth, armor)

   -- Tile mapping: [full hearts][missing hearts] = tile index
   local tileMap = {
      [0] = { [1] = 221, [2] = 222, [3] = 223, [4] = 224 },
      [1] = { [0] = 214, [1] = 211, [2] = 212, [3] = 213 },
      [2] = { [0] = 217, [1] = 215, [2] = 216 },
      [3] = { [0] = 219, [1] = 218 },
      [4] = { [0] = 220 }
   }

   -- Each tile represents 4 health points (4 tiles = 16 max health)
   for i = 1, 4 do
      local tileStartHealth = (i - 1) * 4 + 1 -- Health points this tile starts at (1, 5, 9, 13)

      local beforeInTile = math.max(0, math.min(4, beforeHealth - tileStartHealth + 1))
      local afterInTile = math.max(0, math.min(4, afterHealth - tileStartHealth + 1))
      local missingInTile = beforeInTile - afterInTile

      if afterHealth <= 0 then
         -- Dead state
         tiles[i] = {
            index = 211,
            fg = C.HEALTH_DEAD_FG,
            bg = prism.Color4.TRANSPARENT
         }
      elseif beforeInTile == 0 then
         -- No hearts were ever in this tile
         tiles[i] = {
            index = 220, --immaterial
            fg = prism.Color4.TRANSPARENT,
            bg = prism.Color4.TRANSPARENT
         }
      else
         -- Look up the appropriate tile based on full and missing hearts
         local index = tileMap[afterInTile][missingInTile]

         tiles[i] = {
            index = index + 1,
            fg = C.HEALTH_FULL,
            bg = prism.Color4.TRANSPARENT
         }
      end
   end

   -- Render armor on the rightmost tile if present
   if armor and armor > 0 then
      -- Ensure armor is an integer for table lookup
      local armorValue = math.floor(math.min(armor, 4))

      local armorTileIndices = {
         [1] = 205,
         [2] = 206,
         [3] = 207,
         [4] = 208
      }

      local armorIndex = armorTileIndices[armorValue]

      if armorIndex then
         tiles[4] = {
            index = armorIndex,
            fg = prism.Color4.WHITE,
            bg = prism.Color4.TRANSPARENT
         }
      end
   end

   return tiles
end

--- Turn a string into an array of strings based on available
--- width to render the string.
---@param text string
---@param maxCharsPerLine integer
---@return string[]
local function wrap(text, maxCharsPerLine)
   local lines = {}
   local line = ""

   for word in text:gmatch("%S+") do
      local testLine = line == "" and word or (line .. " " .. word)

      if #testLine <= maxCharsPerLine then
         line = testLine
      else
         if line ~= "" then
            table.insert(lines, line)
         end
         line = word
      end
   end

   if line ~= "" then
      table.insert(lines, line)
   end

   return lines
end

local function defaultWeaponLoad(actor)
   prism.logger.info("LOADING DEFAULT WEAPONS ON PLAYER")
   local inventory = actor:expect(prism.components.Inventory)
   local slots = actor:expect(prism.components.Slots)

   local pistol = prism.actors.Pistol()
   pistol:give(prism.components.Active())
   inventory:addItem(AMMO_TYPES["Pistol"](12))
   -- inventory:addItem(pistol)
   slots:insert(pistol)

   -- local concussion = prism.actors.SmokeGrenade(4)
   -- slots:insert(concussion)

   -- local rifle = prism.actors.Rifle()
   -- slots:insert(rifle)
   -- inventory:addItem(AMMO_TYPES["Rifle"](60))

   local melee = prism.actors.Knife()
   slots:insert(melee)

   -- local shotgun = prism.actors.Shotgun()
   -- inventory:addItem(shotgun)
   -- inventory:addItem(AMMO_TYPES["Shotgun"](20))
end

local function getWeaponString(weapon)
   -- make a multi line string that has the key
   -- details about a weapon.

   local effect = weapon:get(prism.components.Effect)
   local range = weapon:get(prism.components.Range)
   local clip = weapon:get(prism.components.Clip)
   local template = weapon:get(prism.components.Template)

   local effectString = ""
   if effect then
      if effect.health then
         effectString = effectString .. "DMG " .. tostring(effect.health) .. " "
      end

      if effect.push then
         effectString = effectString .. "PSH " .. tostring(effect.push) .. " "
      end

      if effect.spawnActor then
         effectString = "SPECIAL " .. string.lower(effect.spawnActor)
      end
   end

   local rangeString = ""
   if range then
      rangeString = "RNG " .. tostring(range.max)
   end

   local clipString = ""
   if effect.clip then
      clipString = "CLP " .. tostring(effect.clip.max) .. " "

      if effect.clip.turns and effect.clip.turns > 1 then
         clipString = "RLD " .. tostring(effect.clip.turns)
      end
   end

   -- we need to make this multi-line
   -- local nameString = weapon:getName(0)
   local strings = { effectString, rangeString, clipString }

   local finalString = {}
   for _, string in ipairs(strings) do
      if #string > 0 then
         table.insert(finalString, string)
      end
   end

   return finalString
end

--- Calculate profits from player's inventory and slots
--- @param player Actor? The player actor
--- @return table[] Array of profit line items with name and amount
local function calculateProfits(player)
   local profits = {}

   if not player then
      return profits
   end

   -- Get credits from inventory
   if player:has(prism.components.Inventory) then
      local inventory = player:expect(prism.components.Inventory)
      local credits = inventory:getStack("credits")

      if credits then
         local creditCount = credits:expect(prism.components.Item).stackCount
         if creditCount > 0 then
            table.insert(profits, { name = "CREDITS", amount = creditCount })
         end
      end
   end

   -- Get extracted items from slots
   if player:has(prism.components.Slots) then
      local slots = player:expect(prism.components.Slots)

      for slotNum, item, slotType in slots:iter() do
         if item then
            local itemName = item:getName()
            local value = item:get(prism.components.Value)
            local itemComp = item:get(prism.components.Item)

            -- Get the value per item
            local unitValue = 1
            if value then
               unitValue = value.credits
            end

            -- Calculate total value (accounting for stacks)
            local stackCount = 1
            if itemComp and itemComp.stackCount then
               stackCount = itemComp.stackCount
            end

            local totalValue = unitValue * stackCount

            table.insert(profits, {
               name = itemName:upper(),
               amount = totalValue
            })
         end
      end
   end

   return profits
end

--- Calculate fixed losses for a breach operation
--- @return table[] Array of loss line items with name and amount
local function calculateLosses(player)
   local losses = {}

   local missing = player:expect(prism.components.Health).initial - player:expect(prism.components.Health).value

   -- Fixed costs for the breach operation
   table.insert(losses, { name = "FRAME RENTAL", amount = 75 })
   table.insert(losses, { name = "AMMUNITION LOAD", amount = 50 })
   table.insert(losses, { name = "BREACH FEE", amount = 150 })
   table.insert(losses, { name = "REPAIRS", amount = missing * 5 })

   return losses
end

--- Draw the profit/loss screen layout
--- @param overlayDisplay Display The display to draw on
--- @param centerX number Center X position
--- @param centerY number Center Y position
--- @param profits table[] Array of profit items
--- @param losses table[] Array of loss items
--- @param title string Title text (e.g., "BREACH COMPLETE" or "BREACH FAILED")
--- @param titleColor Color4 Color for the title
local function drawProfitLossScreen(overlayDisplay, centerX, centerY, profits, losses, title, titleColor)
   -- Draw main title
   overlayDisplay:print(
      centerX - math.floor(#title / 2),
      centerY - 2,
      title,
      titleColor
   )

   -- Draw END OF RUN header
   local header = "END OF RUN"
   local separator = "----------"
   overlayDisplay:print(
      centerX - math.floor(#header / 2),
      centerY + 1,
      header,
      prism.Color4.WHITE
   )
   overlayDisplay:print(
      centerX - math.floor(#separator / 2),
      centerY + 2,
      separator,
      prism.Color4.WHITE
   )

   -- Draw profit/loss table
   local profitX = centerX - 18
   local lossX = centerX + 8
   local startY = centerY + 4

   -- Headers
   overlayDisplay:print(profitX, startY, "PROFIT", prism.Color4.WHITE)
   overlayDisplay:print(profitX, startY + 1, "------", prism.Color4.WHITE)

   overlayDisplay:print(lossX, startY, "LOSS", prism.Color4.WHITE)
   overlayDisplay:print(lossX, startY + 1, "----", prism.Color4.WHITE)

   local row = startY + 2

   -- Display profits
   local totalProfit = 0
   for _, profit in ipairs(profits) do
      local profitText = string.format("+%d %s", profit.amount, profit.name)
      overlayDisplay:print(profitX, row, profitText, prism.Color4.GREEN)
      totalProfit = totalProfit + profit.amount
      row = row + 1
   end

   -- Display losses
   local lossRow = startY + 2
   local totalLoss = 0
   for _, loss in ipairs(losses) do
      local lossText = string.format("-%d %s", loss.amount, loss.name)
      overlayDisplay:print(lossX, lossRow, lossText, prism.Color4.RED)
      totalLoss = totalLoss + loss.amount
      lossRow = lossRow + 1
   end

   -- Use the larger of the two row counts for positioning the net total
   local maxRow = math.max(row, lossRow)

   -- Draw net profit/loss
   local net = totalProfit - totalLoss
   local netText
   local netColor
   if net > 0 then
      netText = string.format("NET PROFIT: +%d", net)
      netColor = prism.Color4.GREEN
   elseif net < 0 then
      netText = string.format("NET LOSS: %d", net)
      netColor = prism.Color4.RED
   else
      netText = "NET: 0 (BREAK EVEN)"
      netColor = prism.Color4.YELLOW
   end

   overlayDisplay:print(
      centerX - math.floor(#netText / 2),
      maxRow + 1,
      netText,
      netColor
   )

   return maxRow + 3 -- Return Y position for additional content (e.g., instructions)
end

return {
   calculateHealthTiles = calculateHealthTiles,
   calculateHealthBarTiles = calculateHealthBarTiles,
   wrap = wrap,
   defaultWeaponLoad = defaultWeaponLoad,
   getWeaponString = getWeaponString,
   calculateProfits = calculateProfits,
   calculateLosses = calculateLosses,
   drawProfitLossScreen = drawProfitLossScreen
}
