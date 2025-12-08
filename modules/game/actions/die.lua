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

   if self.owner:has(prism.components.Explosive) then
      local explode = prism.actions.Explode(self.owner, self.owner:getPosition(), 2)
      level:tryPerform(explode)
   end

   level:removeActor(self.owner)
end

return Die
