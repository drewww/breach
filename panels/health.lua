local HealthPanel = Panel:extend("HealthPanel")

function HealthPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Health) then
      local health = player:expect(prism.components.Health)

      self.display:print(1, 1, "hp " .. tostring(health.value) .. "/" .. tostring(health.initial), prism.Color4.WHITE,
         prism.Color4.BLACK)
   end

   self.super.cleanupPut(self)
end

return HealthPanel
