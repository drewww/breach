local PushTarget = prism.Target():isActor()
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
   for i, result in ipairs(pushResults) do
      if not result.collision then
         local success, err = level:tryPerform(prism.actions.Move(target, result.pos))
      end
   end
end

return Push
