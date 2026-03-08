local Destination = prism.Target():isPrototype(prism.Vector2)
local Hunt = prism.Target():isType("boolean")

---@class SetDestination : Action
local SetDestination = prism.Action:extend("SetDestination")

SetDestination.targets = { Destination, Hunt }

function SetDestination:canPerform(level, destination)
   return level:inBounds(destination:decompose())
end

function SetDestination:perform(level, destination, hunt)
   local updated = false
   local component = self.owner:get(prism.components.Destination)
   if component then
      if destination ~= component.pos then
         component.pos = destination
         updated = true
      end

      component.hunt = hunt
   else
      component = prism.components.Destination(destination)
      component.hunt = hunt

      self.owner:give(component)
      updated = true
   end

   if updated and destination or not component.path then
      prism.logger.info("generating path to : ", destination)

      -- do some kind of bounds checking here

      local path = level:findPath(self.owner:getPosition(), destination, self.owner,
         self.owner:expect(prism.components.Mover).mask, 1, "8way",
         function(x, y)
            -- removed mine avoidance for now
            -- for _, pos in ipairs(positionsToAvoid) do
            --    if pos.x == x and pos.y == y then
            --       -- TODO this could be health-aware; if you can tank the mine, maybe do it??
            --       return 200
            --    end
            -- end
            local cost = 1

            -- Bounds check before accessing wallDistanceMap
            if level.wallDistanceMap and level:inBounds(x, y) then
               -- check cardinal adjacencies for walls
               cost = level.wallDistanceMap[x][y] * 2
            end

            -- TODO add wall adjacency avoiding here
            return cost
         end)
      component.path = path
      prism.logger.info("set path to ", component.path)
   end

   if not destination then
      component.path = nil
      component.age = 0
   end

   self.owner:give(component)

   return true
end

return SetDestination
