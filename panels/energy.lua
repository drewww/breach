local EnergyPanel = Panel:extend("EnergyPanel")

function EnergyPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Energy) then
      local energy = player:expect(prism.components.Energy)

      self.display:print(0, 0, "energy", prism.Color4.WHITE,
         C.UI_BACKGROUND)

      for i = 1, energy.max do
         local color = i % 2 == 0 and prism.Color4.BLUE or prism.Color4.BLUE:lerp(prism.Color4.BLACK, 0.1)

         if i > energy.current then
            color = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
         end

         self.display:rectangle("fill", i - 1, 1, 1, 2, " ", prism.Color4.TRANSPARENT, color)
      end
   end

   self.super.cleanupPut(self)
end

return EnergyPanel
