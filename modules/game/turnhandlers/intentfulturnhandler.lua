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
   prism.logger.info("handleTurn. actor: ", actor:getName())
   if actor:has(prism.components.BehaviorController) then
      -- look up the controller's intent, execute that.
      local intent = prism.actions.Wait(actor)
      if controller.intent and prism.Action:is(intent) then
         intent = controller.intent
      end

      prism.logger.info("TURN: firing intent: ", intent:getName())
      level:perform(intent)

      local decision = controller:decide(level, actor, prism.decisions.ActionDecision(actor))

      if decision.action then
         controller.intent = decision.action
         prism.logger.info("TURN: set next intent: ", controller.intent:getName())
      end
   else
      local decision = controller:decide(level, actor, prism.decisions.ActionDecision(actor))
      local action = decision.action

      -- we make sure we got an action back from the controller for sanity's sake
      assert(action, "Actor " .. actor:getName() .. " returned nil from decide/act.")

      level:perform(action)
   end
end

return IntenfulTurnHandler
