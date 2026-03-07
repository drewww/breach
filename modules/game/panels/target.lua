local getWeaponString = require("util.helpers").getWeaponString
local wrap = require("util.helpers").wrap

--- @class TargetPanel : Panel
--- @field mouseOverActor? Actor
--- @field mouseCellPosition? Vector2

local PanelHelpers = require "util.panelhelpers"

local X_OFFSET = 9

local TargetPanel = spectrum.Panel:extend("TargetPanel")

function TargetPanel:__new(display, textDisplay, pos)
   TargetPanel.super.__new(self, textDisplay, pos)
   self.entityDisplay = display
end

--- @param level Level
function TargetPanel:put(level)
   self.super.preparePut(self)

   local display = self.display
   local yOffset = -5

   display:rectangle("fill", X_OFFSET - 1, yOffset, 24, 20, "", prism.Color4.TRANSPARENT, prism.Color4.BLACK)

   if self.mouseOverActor then
      -- Display actor name
      display:print(X_OFFSET, yOffset, self.mouseOverActor:getName(), prism.Color4.WHITE, prism.Color4.BLACK)
      yOffset = yOffset + 1


      -- self.entityDisplay:putActor(2, 21, self.mouseOverActor)
      -- self.display:rectangle("fill",)
      self.entityDisplay:putActor(2, 19, self.mouseOverActor)

      -- Display health bar if target has health
      if self.mouseOverActor:has(prism.components.Health) then
         local health = self.mouseOverActor:expect(prism.components.Health)

         if health.initial and health.initial > 1 then
            display:print(X_OFFSET, yOffset, "HP", prism.Color4.WHITE, prism.Color4.BLACK)
            PanelHelpers.drawBar(display, X_OFFSET + 3, yOffset, health.value, health.initial, prism.Color4.RED)
            yOffset = yOffset + 1
         end
      end

      if self.mouseOverActor:has(prism.components.BehaviorState) then
         local state = self.mouseOverActor:expect(prism.components.BehaviorState)

         local colors = { PATROLLING = prism.Color4.GREEN, HUNTING = prism.Color4.RED }

         if state.state ~= "none" then
            local color = colors[state.state]

            local string = " " .. state.state .. " "
            display:print(X_OFFSET, yOffset, string, prism.Color4.BLACK, color and color or prism.Color4.PINK)

            yOffset = yOffset + 1
         end
      end

      if self.mouseOverActor:has(prism.components.Inventory) then
         local activeWeapon = self.mouseOverActor:expect(prism.components.Inventory):query(prism.components.Active)
             :first()

         if activeWeapon then
            local strings = getWeaponString(activeWeapon)

            for i, string in ipairs(strings) do
               display:print(X_OFFSET, yOffset + i - 1, string, prism.Color4.WHITE, prism.Color4.BLACK)
            end
            yOffset = yOffset + #strings
         end
      end

      if self.mouseOverActor:has(prism.components.Item) then
         if self.mouseOverActor:has(prism.components.Ability) then
            local strings = getWeaponString(self.mouseOverActor)

            for i, string in ipairs(strings) do
               display:print(X_OFFSET, yOffset + i - 1, string, prism.Color4.WHITE, prism.Color4.BLACK)
            end
            yOffset = yOffset + #strings
         end

         if self.mouseOverActor:has(prism.components.Accumulated) then
            local stack = self.mouseOverActor:expect(prism.components.Item)
            display:print(X_OFFSET, yOffset, "NUM " .. tostring(stack.stackCount))
            yOffset = yOffset + 1
         end
         -- name will be on top, so what we need to do
         -- show what the item is
         -- options include: value if it has it
         -- weapon stats (if it has them)
         -- ammo?
      end

      -- Display flavor text if present (works for all actors)
      if self.mouseOverActor:has(prism.components.Flavor) then
         yOffset = yOffset + 1
         local flavor = self.mouseOverActor:expect(prism.components.Flavor)

         local rows = wrap(flavor.str, 26)
         for _, row in ipairs(rows) do
            display:print(X_OFFSET, yOffset, row, prism.Color4(0.7, 0.7, 0.7), prism.Color4.BLACK)
            yOffset = yOffset + 1
         end
      end
   elseif self.mouseCellPosition and level:getCell(self.mouseCellPosition:decompose()) then
      local cell = level:getCell(self.mouseCellPosition:decompose())
      display:print(X_OFFSET, yOffset, cell:getName())
      yOffset = yOffset + 1
      self.entityDisplay:putActor(2, 19, cell)
   end

   self.super.cleanupPut(self)
end

return TargetPanel
