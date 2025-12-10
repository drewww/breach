local RocketController = prism.components.Controller:extend("RocketController")
RocketController.name = "RocketController"

--- @class RocketController : Controller
--- @field vector Vector2
--- @field path Path
--- @field lastPos Vector2 Holds the last position we moved to, to sense if we have been pushed.

ROCKET_SPEED = 3

function RocketController:__new()

end

--- @param level Level
--- @param actor Actor
function RocketController:act(level, actor)
   local player = level:query(prism.components.PlayerController):first()
   -- local pushed = actor:getPosition():equals(self.lastPos:decompose())

   prism.logger.info("recalculating path")

   if not self.vector and player then
      self.vector = (player:getPosition() - actor:getPosition()):normalize() * 1
   end

   -- recalculate every time, just don't reset to the PLAYER every time.
   -- the vector will retain for the purposes of pathing.

   -- we want to plot a path that goes effectively forever in this direction. however bresenham needs a destination. we can't just pass `bounds` in as the passability callback, because it will try to route around it or just say "no" when it can't. we could just make it 50 for now and move on. the action will catch it.
   local destination = self.vector * 50
   local x, y = 0, 0
   local dx, dy = destination:decompose()

   prism.logger.info(x, y, dx, dy)
   local path = prism.Bresenham(x, y, math.floor(dx + 0.5), math.floor(dy + 0.5))

   -- TODO think about this in an intent world.
   if actor:has(prism.components.Facing) then
      local facing = actor:expect(prism.components.Facing)

      facing.dir = self.vector

      if actor:has(prism.components.Drawable) then
         local drawable = actor:expect(prism.components.Drawable)
         facing:updateDrawable(drawable)
      end
   end

   if path then
      self.path = path.path

      -- strip the first element
      table.remove(self.path, 1)
   end

   for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
      if entity:has(prism.components.Controller) and entity ~= actor then
         return prism.actions.Die(actor)
      end
   end

   -- no checks -- just GO. let the action work it out.
   local nextMoves = {}
   for i = 1, math.min(ROCKET_SPEED, #self.path) do
      table.insert(nextMoves, table.remove(self.path, 1))
   end

   if #nextMoves == 0 then
      return prism.actions.Die(actor)
   else
      ---@type Vector2[]
      local intentMoves = {}
      if actor:has(prism.components.MoveIntent) then
         intentMoves = actor:expect(prism.components.MoveIntent).moves
         actor:remove(prism.components.MoveIntent)
      end

      prism.logger.info("moves: ", #intentMoves)
      -- now add the NEXT move in.
      -- move relative to position, baed on the intent.
      actor:give(prism.components.MoveIntent(nextMoves))

      if #intentMoves > 0 then
         local adjustedMoves = {}
         for _, m in ipairs(intentMoves) do
            prism.logger.info("move: ", m + actor:getPosition())
            table.insert(adjustedMoves, m + actor:getPosition())
         end

         return prism.actions.Fly(actor, adjustedMoves)
      else
         return prism.actions.Wait(actor)
      end
   end
end

return RocketController
