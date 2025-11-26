--- @class DiffusionSystem : System
local DiffusionSystem = prism.System:extend("DiffusionSystem")

local function accumulateGas(nextGasMap, x, y, value)
   local nextGasValue = nextGasMap:get(x, y) or 0
   nextGasValue = nextGasValue + value
   nextGasMap:set(x, y, nextGasValue)

   return nextGasValue
end

function DiffusionSystem:onTick(level)
   -- get all the entities with a Gas component
   -- put them into a SparseMap


   -- this map stores Actors
   local gasActorsMap = prism.SparseGrid()

   -- this map stores future gas values
   local nextGasMap = prism.SparseGrid()

   local gasActors = level:query(prism.components.Gas):gather()

   for _, gasA in ipairs(gasActors) do
      local x, y = gasA:getPosition():decompose()
      gasActorsMap:set(x, y, gasA)
   end

   -- now, go back through the map and compute new values
   -- reuse the initial set, it's the same objects. we just
   -- needed the map completely built before we can do diffusion
   for _, gasA in ipairs(gasActors) do
      local gasC = gasA:get(prism.components.Gas)
      local x, y = gasA:getPosition():decompose()

      if gasC then
         local keep_ratio = 0.6
         local spread_ratio = 0.1

         accumulateGas(nextGasMap, x, y, keep_ratio * gasC.volume)

         -- now push into neighbors
         for _, neighbor in ipairs(prism.neighborhood8) do
            local nx, ny = x + neighbor.x, y + neighbor.y

            -- TODO consider adding passability checks here. could even
            -- have a "gas" move type if we wanted
            if level:inBounds(nx, ny) then
               accumulateGas(nextGasMap, nx, ny, spread_ratio * gasC.volume)
            else
               -- if you can't spread, increase this cell's amount
               accumulateGas(nextGasMap, x, y, spread_ratio * gasC.volume)
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

   -- finally, go back to the gas map and if there are any gasComponents that
   -- did not get updated OR whose volume is <0.1 (or something) delete the
   -- gas entity entirely.
end

return DiffusionSystem
