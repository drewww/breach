--- @class DiffusionSystem : System
local DiffusionSystem = prism.System:extend("DiffusionSystem")

local function accumulateGas(nextGasMap, x, y, value)
   local nextGasValue = nextGasMap:get(x, y) or 0
   nextGasValue = nextGasValue + value
   nextGasMap:set(x, y, nextGasValue)

   return nextGasValue
end

-- local KEEP_RATIO = 0.8
-- local SPREAD_RATIO = (1 - KEEP_RATIO) / 8 -- 8 neighbors, conserve
-- local REDUCE_RATIO = 0.90
-- local MINIMUM_VOLUME = 0.5
-- local OPAQUE_THRESHOLD = 2.0

GAS_TYPES = {
   smoke = {
      factory = prism.actors.Smoke,
      keep_ratio = 0.8,
      spread_radio = 0.2 / 8,
      reduce_ratio = 0.9,
      minimum_volume = 0.5,
      threshold = 2.0
   }
}

-- TODO generalize off Smoke.
function DiffusionSystem:onTurnEnd(level, actor)
   if not actor:has(prism.components.PlayerController) then
      return
   end
   -- get all the entities with a Gas component
   -- put them into a SparseMap

   for gasType, params in pairs(GAS_TYPES) do
      -- this map stores Actors
      local gasActorsMap = prism.SparseGrid()

      -- this map stores future gas values
      local nextGasMap = prism.SparseGrid()

      local gasActors = level:query(prism.components.Gas):gather()

      for _, gasA in ipairs(gasActors) do
         -- filter out any gas that does not match the type currently
         -- being processed.
         --- @type Gas
         local gasC = gasA:get(prism.components.Gas)

         if gasC.type == gasType then
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

         if gasC and gasC.type == gasType then
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

         if drawable and gasC and gasC.type == gasType then
            -- clamp it
            local scale = math.max(math.min(math.pow(gasC.volume, 0.5) / 10, 1.0), 0.0)

            if gasC.volume > params.threshold then
               drawable.background = prism.Color4.WHITE
               gasA:give(prism.components.Opaque())
            else
               drawable.background = prism.Color4.DARKGREY
               if gasA:has(prism.components.Opaque) then
                  gasA:remove(prism.components.Opaque)
               end
            end
         end
      end
   end
end

return DiffusionSystem
