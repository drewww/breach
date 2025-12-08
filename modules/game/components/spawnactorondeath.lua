--- @class SpawnActorOnDeath : Component
--- @field actor ActorFactory factor to spawn from
--- @field params table an array of paramters to be passed to the actor factor to spawn the actor.

local SpawnActorOnDeath = prism.Component:extend("SpawnActorOnDeath")
SpawnActorOnDeath.name = "SpawnActorOnDeath"


---@param actor ActorFactory
---@param params table
function SpawnActorOnDeath:__new(actor, params)
   prism.logger.info("actor: ", actor)
   self.actor = actor
   self.params = params
end

return SpawnActorOnDeath
