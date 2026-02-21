--- Helper function to calculate health tile display data
--- @param healthValue number The current health value
--- @return (number|string)[] Array of characters/numbers for health tiles
local function calculateHealthTiles(healthValue)
   local tiles = {}

   if healthValue <= 0 then
      -- If dead or dying, show 4 'x' characters
      for i = 1, 4 do
         tiles[i] = "x"
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

--- Helper function to calculate health bar display using 5-step tiles
--- @param beforeHealth number The health before damage
--- @param afterHealth number The health after damage
--- @return table[] Array of tile data with index, fg, and bg colors
local function calculateHealthBarTiles(beforeHealth, afterHealth)
   local tiles = {}

   -- Sprite indices for health values 1-4 (0 uses 220 with transparent colors)
   local spriteIndices = { 217, 218, 219, 220 }

   -- Each tile represents 4 health points (4 tiles = 16 max health)
   for i = 1, 4 do
      local tileStartHealth = (i - 1) * 4 + 1 -- Health points this tile starts at (1, 5, 9, 13)
      local tileEndHealth = i * 4             -- Health points this tile ends at (4, 8, 12, 16)

      local beforeInTile = math.max(0, math.min(4, beforeHealth - tileStartHealth + 1))
      local afterInTile = math.max(0, math.min(4, afterHealth - tileStartHealth + 1))

      if afterHealth <= 0 then
         -- Dead state
         tiles[i] = {
            index = "X",
            fg = C.HEALTH_DEAD_FG,
            bg = C.HEALTH_DEAD_BG
         }
      elseif afterInTile == 0 then
         -- Empty tile (0 health in this tile)
         tiles[i] = {
            index = 220,
            fg = prism.Color4.TRANSPARENT,
            bg = prism.Color4.TRANSPARENT
         }
      else
         -- Use sprite index based on health value (1-4)
         local index = spriteIndices[afterInTile]
         local fg, bg

         if beforeInTile == afterInTile then
            -- No change in this tile
            fg = C.HEALTH_FULL
            bg = C.HEALTH_FULL
         elseif beforeInTile > afterInTile then
            -- Lost health in this tile
            fg = C.HEALTH_FULL
            bg = prism.Color4.TRANSPARENT
         else
            -- Gained health (if applicable)
            fg = C.HEALTH_FULL
            bg = C.HEALTH_FULL
         end

         tiles[i] = {
            index = index,
            fg = fg,
            bg = bg
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

return {
   calculateHealthTiles = calculateHealthTiles,
   calculateHealthBarTiles = calculateHealthBarTiles,
   wrap = wrap
}
