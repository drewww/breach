local PanelHelpers = require "util.panelhelpers"

local PlayerPanel = spectrum.Panel:extend("PlayerPanel")

function PlayerPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Health) then
      local health = player:expect(prism.components.Health)

      self.display:print(0, 0, "HP", prism.Color4.WHITE,
         prism.Color4.TRANSPARENT)

      PanelHelpers.drawBar(self.display, 3, 0, health.value, health.initial, prism.Color4.RED)
   end

   if player:has(prism.components.Energy) then
      local energy = player:expect(prism.components.Energy)

      self.display:print(0, 1, "EN", prism.Color4.WHITE,
         prism.Color4.TRANSPARENT)

      PanelHelpers.drawBar(self.display, 3, 1, energy.current, energy.max, prism.Color4.BLUE)
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
