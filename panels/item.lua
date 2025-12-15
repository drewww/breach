local ItemPanel = Panel:extend("ItemPanel")

function ItemPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Inventory) then
      local activeItem = player:expect(prism.components.Inventory):query(prism.components.Ability,
         prism.components.Active):first()

      if activeItem then
         self.display:print(1, 1, activeItem:getName(), prism.Color4.WHITE,
            prism.Color4.BLACK)
      end
   end

   self.super.cleanupPut(self)
end

return ItemPanel
