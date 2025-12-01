--- @class DiffusionSystem : System
local DiffusionSystem = prism.System:extend("DiffusionSystem")

-- There needs to be a multiple on scorch intensities, since tiles get hit multiple times per diffuse step on spread actions, but only once per turn on resting gasses. So one intensity value does not work for both types of scorching. This sets how to scale them.
local STATIC_SCORCH_INTENSITY_MULTIPLIER = 4

local function lookupExistingGas(x, y, gasLookup, gasData)
   local existingActor = nil
   if gasLookup[x] and gasLookup[x][y] then
      local index = gasLookup[x][y]
      existingActor = gasData[index].actor
   end

   return existingActor
end

local function applyScorch(level, source, target, color, intensity)
   local scorchAction = prism.actions.Scorch(source, target, color,
      intensity)

   local canPerform, error = level:canPerform(scorchAction)
   if canPerform then
      level:perform(scorchAction)
   end
end

local function applyDamage(level, source, target, damage)
   local spreadDamageAction = prism.actions.Damage(source, target, damage)

   local canPerform, error = level:canPerform(spreadDamageAction)
   if canPerform then
      level:perform(spreadDamageAction)
   end
end

--- @param level Level
--- @param curGasType "poison" | "fire" | "smoke" type of gas to diffuse, must be a key in GAS_TYPES
local function diffuseGasType(level, curGasType)
   local params = GAS_TYPES[curGasType]

   -- Extract gas data from actors into simple arrays
   local gasData = {}   -- array of {x, y, volume, actor}
   local gasLookup = {} -- lookup table: gasLookup[x][y] = index in gasData

   local gasActors = level:query(prism.components.Gas):gather()

   -- Extract data from matching gas actors
   for _, gasA in ipairs(gasActors) do
      --- @type Gas
      local gasC = gasA:get(prism.components.Gas)

      if gasC.type == curGasType then
         local x, y = gasA:getPosition():decompose()

         local gasEntry = {
            x = x,
            y = y,
            volume = gasC.volume,
            actor = gasA
         }

         table.insert(gasData, gasEntry)

         -- Build lookup table
         if not gasLookup[x] then
            gasLookup[x] = {}
         end
         gasLookup[x][y] = #gasData
      end
   end

   -- Process diffusion with simple data structures
   local newGasData = {}   -- array of {x, y, volume}
   local newGasLookup = {} -- lookup table for new gas positions

   local function addToNewGas(x, y, volume)
      if not newGasLookup[x] then
         newGasLookup[x] = {}
      end

      if newGasLookup[x][y] then
         local index = newGasLookup[x][y]
         newGasData[index].volume = newGasData[index].volume + volume
      else
         local newEntry = { x = x, y = y, volume = volume }
         table.insert(newGasData, newEntry)
         newGasLookup[x][y] = #newGasData
      end
   end

   -- Compute diffusion for each gas cell
   for _, gas in ipairs(gasData) do
      local x, y, volume = gas.x, gas.y, gas.volume

      -- Keep some gas at current position
      addToNewGas(x, y, params.keep_ratio * volume)

      -- Spread to neighbors
      for _, neighbor in ipairs(prism.neighborhood) do
         local nx, ny = x + neighbor.x, y + neighbor.y

         if level:inBounds(nx, ny) and level:getCellPassable(nx, ny, prism.Collision.createBitmaskFromMovetypes { "walk" }) then
            addToNewGas(nx, ny, params.spread_radio * volume)
         else
            -- if you can't spread, increase this cell's amount
            addToNewGas(x, y, params.spread_radio * volume)

            -- if we have spread damage, apply it here.
            if params.spread_damage or (params.scorch_color and params.scorch_intensity) then
               local entitiesAtTarget = level:query():at(nx, ny):gather()
               local cellAtTarget = level:getCell(nx, ny)
               local gasSourceEntity = lookupExistingGas(x, y, gasLookup, gasData)

               -- add cells at the target, too.
               if cellAtTarget then
                  table.insert(entitiesAtTarget, cellAtTarget)
               end

               for _, e in ipairs(entitiesAtTarget) do
                  if params.spread_damage and e:has(prism.components.Health) then
                     applyDamage(level, gasSourceEntity, e, params.spread_damage)
                  end

                  if params.scorch_color and params.scorch_intensity and e:has(prism.components.Scorchable) then
                     applyScorch(level, gasSourceEntity, e, params.scorch_color, params.scorch_intensity)
                  end
               end
            end
         end
      end
   end

   -- Apply reduction and reconcile with world
   for _, newGasEntry in ipairs(newGasData) do
      local x, y = newGasEntry.x, newGasEntry.y
      local volume = newGasEntry.volume * params.reduce_ratio

      -- Find existing actor at this position
      local existingActor = lookupExistingGas(x, y, gasLookup, gasData)

      if volume <= params.minimum_volume then
         -- Remove existing actor if volume too low
         if existingActor then
            level:removeActor(existingActor)
         end
      else
         -- Update or create actor
         --- @type Actor
         local gasActor = nil
         if existingActor then
            gasActor = existingActor
            local gasC = existingActor:get(prism.components.Gas)
            gasC.volume = volume
         else
            -- TODO fix this by making gases a proper object. See Discord example.
            gasActor = params.factory(volume)
            level:addActor(gasActor, x, y)
         end

         -- Apply damage and scorch here.
         ---@type Entity[]
         local entitiesAtTarget = level:query():at(x, y):gather()
         local tile = level:getCell(x, y)
         if tile then
            table.insert(entitiesAtTarget, tile)
         end

         for _, entity in ipairs(entitiesAtTarget) do
            if entity ~= gasActor then
               if entity:has(prism.components.Health) then
                  applyDamage(level, gasActor, entity, params.cell_damage)
               end

               if entity:has(prism.components.Scorchable) then
                  applyScorch(level, gasActor, entity, params.scorch_color,
                     params.scorch_intensity * STATIC_SCORCH_INTENSITY_MULTIPLIER)
               end
            end
         end
      end
   end

   -- Remove any actors that weren't updated (no longer have gas)
   for _, gasEntry in ipairs(gasData) do
      local x, y = gasEntry.x, gasEntry.y
      local wasUpdated = newGasLookup[x] and newGasLookup[x][y] and
          newGasData[newGasLookup[x][y]].volume > params.minimum_volume

      if not wasUpdated then
         level:removeActor(gasEntry.actor)
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
      bg_fading = prism.Color4.GREY,
      spread_damage = 0,
      scorch_color = nil,
      scorch_intensity = nil,
      cell_damage = 0
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
      bg_fading = prism.Color4.YELLOW,
      spread_damage = 1,
      scorch_intensity = 0.1,
      scorch_color = prism.Color4.DARKGREY,
      cell_damage = 2
   },
   poison = {
      factory = prism.actors.Poison,
      keep_ratio = 0.0,
      spread_radio = 1.00 / 8,
      reduce_ratio = 0.99,
      minimum_volume = 0.5,
      threshold = 3.0,
      fg = prism.Color4.WHITE,
      bg_full = prism.Color4.LIME,
      bg_fading = prism.Color4.GREEN,
      spread_damage = 1,
      scorch_color = prism.Color4.LIME,
      scorch_intensity = 0.01,
      cell_damage = 1
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
