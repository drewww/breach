local Destination = prism.Target():isPrototype(prism.Vector2)

---@class SetDestination : Action
local SetDestination = prism.Action:extend("SetDestination")

SetDestination.targets = { Destination }

function SetDestination:canPerform()
   return true
end

function SetDestination:perform(level, destination)
   local updated = false
   local component = self.owner:get(prism.components.Destination)
   if component then
      if destination ~= component.pos then
         component.pos = destination
         updated = true
      end
   else
      component = prism.components.Destination(destination)
      self.owner:give(component)
      updated = true
   end

   if updated and destination then
      prism.logger.info("Updated destination to: ", destination)
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

            -- TODO add wall adjacency avoiding here
            return 1
         end)
      component.path = path
   end

   if not destination then
      component.path = nil
      component.age = 0
   end

   self.owner:give(component)

   return true
end

return SetDestination
