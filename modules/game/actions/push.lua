local PushTarget = prism.Target():isActor():without(prism.components.Immoveable, prism.components.Gas)
local PushVector = prism.Target():isVector2()
local PushAmount = prism.Target():isType("number")
local SuppressDamage = prism.Target():isType("boolean")

---@class Push : Action
--- @field collision boolean true if the push resulted in a collision
--- @field results PushResult[]
--- @field steps number
local Push = prism.Action:extend("Push")

Push.targets = { PushTarget, PushVector, PushAmount, SuppressDamage }

function Push:canPerform(level, target, vector, amount, suppress)
   self.collision = false

   self.results, self.steps = RULES.pushResult(level, target, vector, amount)

   for i, result in ipairs(self.results) do
      if result.collision then
         self.collision = true
      end
   end

   return true
end

function Push:perform(level, target, vector, amount, suppress)
   -- move to the last non-collision in the list
   for i, result in ipairs(self.results) do
      if not result.collision then
         local success, err = level:tryPerform(prism.actions.Move(target, result.direction, false))
      end
   end

   if self.collision and not suppress then
      local s, e = level:tryPerform(prism.actions.Damage(self.owner, target, COLLISION_DAMAGE, false))
   end

   if target:has(prism.components.Intentful) then
      local controller = target:expect(prism.components.BehaviorController)

      controller.intent = nil

      prism.logger.info("Removing an intent on push.")
   end
end

return Push
