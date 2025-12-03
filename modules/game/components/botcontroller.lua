local BotController = prism.components.Controller:extend("BotController")
BotController.name = "BotController"

--- @param level Level
--- @param actor Actor
function BotController:act(level, actor)
   local senses = actor:expect(prism.components.Senses)
   local mover = actor:expect(prism.components.Mover)

   -- pick a random direction and try to move into it
   local vec = prism.neighborhood[math.random(1, #prism.neighborhood)]
   local move = prism.actions.Move(actor, actor:getPosition() + vec)

   if level:canPerform(move) then
      return move
   else
      return prism.actions.Wait(actor)
   end
end

return BotController
