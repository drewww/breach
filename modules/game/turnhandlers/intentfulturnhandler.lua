--- Handles running turns in a level.
--- Extend this class and pass it to LevelBuilder.addTurnHandler to override.
--- @class IntenfulTurnHandler : TurnHandler
local IntenfulTurnHandler = prism.TurnHandler:extend("IntenfulTurnHandler")

--- Runs a single actor's turn in a level.
--- @param level Level
--- @param actor Actor
--- @param controller Controller
function IntenfulTurnHandler:handleTurn(level, actor, controller)
   if actor:has(prism.components.Intenful) then
      -- look up the controller's intent, execute that.
      local intent = controller.intent or prism.actions.Wait(actor)

      prism.logger.info("TURN: firing intent: ", intent:getName())
      level:perform(intent)

      controller.intent = controller:decide(level, actor, prism.decisions.ActionDecision(actor)) or
          prism.actions.Wait(actor)
      prism.logger.info("TURN: set next intent: ", controller.intent:getName())
   else
      local decision = controller:decide(level, actor, prism.decisions.ActionDecision(actor))
      local action = decision.action

      -- we make sure we got an action back from the controller for sanity's sake
      assert(action, "Actor " .. actor:getName() .. " returned nil from decide/act.")

      level:perform(action)
   end
end

return IntenfulTurnHandler
