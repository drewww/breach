RULES = {}

DASH_DISTANCE = 2
DASH_NEIGHBORHOOD = prism.Vector2.neighborhood4

-- returns a set of valid destination vectors, mapped to moves. so it's
-- neighborhood4 as the keys, and values for where that result would get you.
-- all normalized to 0,0? not actor position.

--- @param level Level
--- @param actor Actor
--- @return table<Vector2, Vector2> A table where the keys are the neighborhood4 vectors, and the values are the farthest you can dash in that direction. The values are relative to actor position, not global
function RULES.dashLocations(level, actor)
   -- first, create the base keys. for now, we're doing neighborhood4 as options.
   local results = {}

   local inputs = DASH_NEIGHBORHOOD

   local mover = actor:expect(prism.components.Mover)

   for _, dir in ipairs(inputs) do
      -- check how far we can go in that direction.
      -- can we generalize this for multiple steps?
      -- we want to return the farthes possible step in each direction.
      local farthestDirection = prism.Vector2(0, 0)


      for distance = 1, DASH_DISTANCE, 1 do
         local dest = actor:getPosition() + dir * distance

         if level:inBounds(dest.x, dest.y) then
            local passable = level:getCellPassableByActor(dest.x, dest.y, actor, mover.mask)

            if passable then
               farthestDirection = dest
            end
         end
      end

      results[dir] = farthestDirection
   end

   return results
end
