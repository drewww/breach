local PushTarget = prism.Target():isActor():without(prism.components.Immoveable, prism.components.Gas)
local PushVector = prism.Target():isVector2()
local PushAmount = prism.Target():isType("number")

---@class Push : Action
local Push = prism.Action:extend("Push")

Push.targets = { PushTarget, PushVector, PushAmount }

function Push:canPerform()
   -- TODO figure out criteria. Target may have "Immovable"?
   return true
end

function Push:perform(level, target, vector, amount)
   local pushResults = RULES.pushResult(level, target, vector, amount)

   -- move to the last non-collision in the list
   local hasCollision = false
   for i, result in ipairs(pushResults) do
      if result.collision then
         hasCollision = true
      else
         local success, err = level:tryPerform(prism.actions.Move(target, result.direction, true))
      end
   end

   if hasCollision then
      local s, e = level:tryPerform(prism.actions.Damage(self.owner, target, COLLISION_DAMAGE))
      prism.logger.info("collision damage: ", s, e)
   end
end

return Push
