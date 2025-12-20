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

   -- Calculate health display tiles (max 16 health = 4 full tiles)
   local fullTiles = math.floor(healthValue / 4)
   local remainder = healthValue % 4

   local healthChars = { 177, 178, 179, 220 } -- indexed by health points (1-4)

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

return {
   calculateHealthTiles = calculateHealthTiles
}
