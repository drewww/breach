---@class Die : Action
local Die = prism.Action:extend("Die")

function Die:canPerform(level)
   return level:hasActor(self.owner)
end

function Die:perform(level)
   if self.owner:has(prism.components.SpawnActorOnDeath) then
      local spawner = self.owner:expect(prism.components.SpawnActorOnDeath)

      prism.logger.info("spawning: ", spawner.actor, spawner.params)
      local actor = spawner.actor(unpack(spawner.params))

      local x, y = self.owner:getPosition():decompose()
      level:addActor(actor, x, y)
   end

   if self.owner:has(prism.components.Explosive) and not self.owner:expect(prism.components.Explosive).exploding then
      local explosive = self.owner:expect(prism.components.Explosive)
      local explode = prism.actions.Explode(self.owner, self.owner:getPosition(), explosive.radius, explosive.damage)
      level:tryPerform(explode)
   end

   local dropTable = self.owner:get(prism.components.DropTable)

   if dropTable then
      local drops = dropTable:getDrops(RNG)
      for _, drop in ipairs(drops) do
         prism.logger.info("dropping: ", drop:getName())
         drop:give(prism.components.Position())
         level:addActor(drop, self.owner:getPosition():decompose())
      end
   end

   level:removeActor(self.owner)
end

return Die
