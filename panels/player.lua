local PlayerPanel = Panel:extend("PlayerPanel")

function PlayerPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Health) then
      local health = player:expect(prism.components.Health)

      self.display:print(0, 0, "HP", prism.Color4.WHITE,
         prism.Color4.TRANSPARENT)

      for i = 1, health.initial do
         local color = i % 2 == 0 and prism.Color4.RED or prism.Color4.RED:lerp(prism.Color4.BLACK, 0.1)

         if i > health.value then
            color = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
         end

         self.display:rectangle("fill", i + 2, 0, 1, 1, " ", prism.Color4.TRANSPARENT, color)
      end
   end

   if player:has(prism.components.Energy) then
      local energy = player:expect(prism.components.Energy)

      self.display:print(0, 1, "EN", prism.Color4.WHITE,
         prism.Color4.TRANSPARENT)

      for i = 1, energy.max do
         local color = i % 2 == 0 and prism.Color4.BLUE or prism.Color4.BLUE:lerp(prism.Color4.BLACK, 0.1)

         if i > energy.current then
            color = prism.Color4.GREY:lerp(prism.Color4.BLACK, 0.5)
         end

         self.display:rectangle("fill", i + 2, 1, 1, 1, " ", prism.Color4.TRANSPARENT, color)
      end
   end

   if player:has(prism.components.Inventory) then
      local credits = player:expect(prism.components.Inventory):getStack("credits")

      local numCredits = 0
      if credits then
         numCredits = credits:expect(prism.components.Item)
             .stackCount
      end

      self.display:print(0, 2, "$$", prism.Color4.WHITE,
         prism.Color4.TRANSPARENT)
      self.display:print(3, 2, tostring(numCredits), prism.Color4.YELLOW)
   end

   self.super.cleanupPut(self)
end

return PlayerPanel
