local getWeaponString = require("util.helpers").getWeaponString


--- @class TargetPanel : Panel
--- @field mouseOverActor? Actor
--- @field mouseCellPosition? Vector2

local PanelHelpers = require "util.panelhelpers"

local TargetPanel = spectrum.Panel:extend("TargetPanel")

function TargetPanel:__new(display, textDisplay, pos)
   TargetPanel.super.__new(self, textDisplay, pos)
   self.entityDisplay = display
end

--- @param level Level
function TargetPanel:put(level)
   self.super.preparePut(self)

   local display = self.display

   if self.mouseOverActor then
      display:print(9, -3, self.mouseOverActor:getName())
      -- self.entityDisplay:putActor(2, 21, self.mouseOverActor)
      -- self.display:rectangle("fill",)
      self.entityDisplay:putActor(2, 20, self.mouseOverActor)

      -- Display health bar if target has health
      if self.mouseOverActor:has(prism.components.Health) then
         local health = self.mouseOverActor:expect(prism.components.Health)
         display:print(4, 0, "HP", prism.Color4.WHITE, prism.Color4.BLACK)
         PanelHelpers.drawBar(display, 6, 0, health.value, health.initial, prism.Color4.RED)
      end

      if self.mouseOverActor:has(prism.components.Inventory) then
         local activeWeapon = self.mouseOverActor:expect(prism.components.Inventory):query(prism.components.Active)
             :first()

         if activeWeapon then
            local string = getWeaponString(activeWeapon)
            display:print(4, 2, string, prism.Color4.WHITE, prism.Color4.BLACK)
         end
      end

      -- elseif self.mouseCellPosition and level:getCell(self.mouseCellPosition:decompose()) then
      --    local cell = level:getCell(self.mouseCellPosition:decompose())
      --    display:print(8, 0, cell:getName())
      --    self.entityDisplay:putActor(2, 21, cell)
   end

   self.super.cleanupPut(self)
end

return TargetPanel
