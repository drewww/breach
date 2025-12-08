local RocketController = prism.components.Controller:extend("RocketController")
RocketController.name = "RocketController"

--- @class RocketController : Controller
--- @field vector Vector2
--- @field path Path

ROCKET_SPEED = 3

function RocketController:__new()

end

--- @param level Level
--- @param actor Actor
function RocketController:act(level, actor)
   if not self.path then
      prism.logger.info("recalculating path")
      local player = level:query(prism.components.PlayerController):first()

      if player then
         local x, y = actor:getPosition():decompose()

         local vector = (player:getPosition() - actor:getPosition()):normalize() * 1

         -- we want to plot a path that goes effectively forever in this direction. however bresenham needs a destination. we can't just pass `bounds` in as the passability callback, because it will try to route around it or just say "no" when it can't. we could just make it 50 for now and move on. the action will catch it.
         local destination = actor:getPosition() + vector * 50
         local dx, dy = destination:decompose()
         local path = prism.Bresenham(x, y, math.floor(dx + 0.5), math.floor(dy + 0.5))


         if path then
            self.path = path.path

            -- strip the first element
            table.remove(self.path, 1)
         end
      end
   end

   -- no checks -- just GO. let the action work it out.
   local steps = {}
   for i = 1, math.min(ROCKET_SPEED, #self.path) do
      table.insert(steps, table.remove(self.path, 1))
   end

   if #steps == 0 then
      return prism.actions.Die(actor)
   else
      return prism.actions.Fly(actor, steps)
   end
end

return RocketController
