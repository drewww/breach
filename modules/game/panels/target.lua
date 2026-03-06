--- @class TargetPanel : Panel
--- @field mouseOverActor? Actor
--- @field mouseCellPosition? Vector2

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
      display:print(8, 0, self.mouseOverActor:getName())
      self.entityDisplay:putActor(2, 21, self.mouseOverActor)
   elseif self.mouseCellPosition and level:getCell(self.mouseCellPosition:decompose()) then
      local cell = level:getCell(self.mouseCellPosition:decompose())
      display:print(8, 0, cell:getName())
      self.entityDisplay:putActor(2, 21, cell)
   end

   self.super.cleanupPut(self)
end

return TargetPanel
