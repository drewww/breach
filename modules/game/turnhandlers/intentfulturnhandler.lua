--- Handles running turns in a level.
--- Extend this class and pass it to LevelBuilder.addTurnHandler to override.
--- @class IntenfulTurnHandler : TurnHandler
local IntenfulTurnHandler = prism.TurnHandler:extend("IntenfulTurnHandler")
-- prism.register(IntenfulTurnHandler())

--- Runs a single actor's turn in a level.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
function IntenfulTurnHandler:handleTurn(level, actor, controller)
   if actor:has(prism.components.BehaviorController) then
      -- look up the controller's intent, execute that.
      local intent = prism.actions.Wait(actor)
      if controller.intent and prism.Action:is(intent) then
         intent = controller.intent
      end

      local s, e = level:canPerform(intent)
      if s then
         level:perform(intent)
         controller.blackboard.priorActionPerformed = true
      else
         prism.logger.info("Cannot perform intent: ", e)
         controller.blackboard.priorActionPerformed = false
      end

      controller.blackboard.priorAction = intent

      -- originally this used the "decide" mechanism and ActionDecision, but that required that the action be performable when set. That clashed with the intent system, and some tricks I was trying to do with mines and triggers and such.
      local action = controller:act(level, actor)

      if action then
         ---@cast controller BehaviorController
         controller.intent = action
      end
   else
      repeat
         local continue = false
         local decision = controller:decide(level, actor, prism.decisions.ActionDecision(actor))
         local action = decision.action

         -- we make sure we got an action back from the controller for sanity's sake
         assert(action, "Actor " .. actor:getName() .. " returned nil from decide/act.")

         local s, e = level:canPerform(action)

         if s then
            level:perform(action)
         end

         if s and prism.actions.Dash:is(action) then
            continue = true
         end
      until not continue
   end
end

return IntenfulTurnHandler
