--- @class DiffusionSystem : System
local DiffusionSystem = prism.System:extend("DiffusionSystem")

local function accumulateGas(nextGasMap, x, y, value)
   local nextGasValue = nextGasMap:get(x, y) or 0
   nextGasValue = nextGasValue + value
   nextGasMap:set(x, y, nextGasValue)

   return nextGasValue
end

--- @param level Level
--- @param curGasType "poison" | "fire" | "smoke" type of gas to diffuse, must be a key in GAS_TYPES
local function diffuseGasType(level, curGasType)
   local params = GAS_TYPES[curGasType]

   -- stores all the gas actors for this gasType.
   local gasActorsMap = prism.SparseGrid()

   -- this map stores future gas values for this gasType.
   local nextGasMap = prism.SparseGrid()

   local gasActors = level:query(prism.components.Gas):gather()

   for _, gasA in ipairs(gasActors) do
      -- filter out any gas that does not match the type currently
      -- being processed.
      --- @type Gas
      local gasC = gasA:get(prism.components.Gas)

      if gasC.type == curGasType then
         local x, y = gasA:getPosition():decompose()
         gasActorsMap:set(x, y, gasA)

         -- mark them all as dirty. if it doesn't get updated in the "write"
         -- pass, then delete it at the end.
         gasC.updated = false
      end
   end

   -- now, go back through the map and compute new values
   -- reuse the initial set, it's the same objects. we just
   -- needed the map completely built before we can do diffusion
   for _, gasA in ipairs(gasActors) do
      local gasC = gasA:get(prism.components.Gas)
      local x, y = gasA:getPosition():decompose()

      if gasC and gasC.type == curGasType then
         accumulateGas(nextGasMap, x, y, params.keep_ratio * gasC.volume)

         -- now push into neighbors
         for _, neighbor in ipairs(prism.neighborhood) do
            local nx, ny = x + neighbor.x, y + neighbor.y

            -- TODO consider adding passability checks here. could even
            -- have a "gas" move type if we wanted
            if level:inBounds(nx, ny) and level:getCellPassable(nx, ny, prism.Collision.createBitmaskFromMovetypes { "walk" }) then
               accumulateGas(nextGasMap, nx, ny, params.spread_radio * gasC.volume)
            else
               -- if you can't spread, increase this cell's amount
               accumulateGas(nextGasMap, x, y, params.spread_radio * gasC.volume)
            end
         end
      end
   end

   -- next, reconcile the nextGasMap with the world. go through it, and update
   -- the actors that exist already or create new ones.
   -- also, before we do that, remove like 0.05 from everything to just dial
   -- gas down naturally.
   --
   -- TODO add an updatedFlag to all the gasComponents. set it to false at the
   -- start, and then true in this step.
   for x, y, v in nextGasMap:each() do
      -- drop the amounts a bit so it is reducing over time naturally
      v = v * params.reduce_ratio
      local gasA = gasActorsMap:get(x, y)



      -- if we're below the minimum volume and there's an actor in the spot,
      -- remove it.
      if v <= params.minimum_volume then
         if gasA then
            level:removeActor(gasA)
         end
      else
         -- if we're above the minimum volume
         if gasA then
            --- @type Gas
            local gasC = gasA:get(prism.components.Gas)
            -- update an existing actor
            gasC.volume = v
            gasC.updated = true
         else
            local newGas = params.factory(v)
            -- insert it into the world
            level:addActor(newGas, x, y)
         end
      end
   end

   -- finally, go back to the gas map and if there are any gasComponents that
   -- did not get updated OR whose volume is <0.1 (or something) delete the
   -- gas entity entirely.
   for x, y, gasA in gasActorsMap:each() do
      --- @type Gas
      local gasC = gasA:get(prism.components.Gas)
      if not gasC.updated then
         level:removeActor(gasA)
      end
   end

   for _, gasA in ipairs(level:query(prism.components.Gas):gather()) do
      local gasC = gasA:get(prism.components.Gas)
      local drawable = gasA:get(prism.components.Drawable)
      --- scale the color to match intensity.

      if drawable and gasC and gasC.type == curGasType then
         -- clamp it
         local scale = math.max(math.min(math.pow(gasC.volume, 0.5) / 10, 1.0), 0.0)

         if gasC.volume > params.threshold then
            drawable.background = params.bg_full

            if curGasType == "smoke" then
               gasA:give(prism.components.Opaque())
            end
         else
            drawable.background = params.bg_fading

            -- not sure how shove this into the params. I could put a post-processed callback, I guess. If I get more stuff I want to do in this phase I can double back and abstract it.
            if gasA:has(prism.components.Opaque) and curGasType == "smoke" then
               gasA:remove(prism.components.Opaque)
            end
         end
      end
   end
end

GAS_TYPES = {
   smoke = {
      factory = prism.actors.Smoke,
      keep_ratio = 0.95,
      spread_radio = 0.05 / 8,
      reduce_ratio = 0.9,
      minimum_volume = 0.5,
      threshold = 2.0,
      fg = prism.Color4.TRANSPARENT,
      bg_full = prism.Color4.WHITE,
      bg_fading = prism.Color4.GREY
   },
   fire = {
      factory = prism.actors.Fire,
      keep_ratio = 0.6,
      spread_radio = 0.4 / 8,
      reduce_ratio = 0.6,
      minimum_volume = 0.5,
      threshold = 1.0,
      fg = prism.Color4.TRANSPARENT,
      bg_full = prism.Color4.RED,
      bg_fading = prism.Color4.YELLOW
   },
   poison = {
      factory = prism.actors.Poison,
      keep_ratio = 0.0,
      spread_radio = 1.05 / 8,
      reduce_ratio = 0.98,
      minimum_volume = 0.5,
      threshold = 3.0,
      fg = prism.Color4.WHITE,
      bg_full = prism.Color4.LIME,
      bg_fading = prism.Color4.GREEN
   }
}

function DiffusionSystem:onTurnEnd(level, actor)
   -- run after the player has acted, effectively once per "loop" of the
   -- actors in the level.
   if not actor:has(prism.components.PlayerController) then
      return
   end

   for curGasType, params in pairs(GAS_TYPES) do
      diffuseGasType(level, curGasType)
   end
end

return DiffusionSystem
