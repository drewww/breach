local RocketController = prism.components.Controller:extend("RocketController")
RocketController.name = "RocketController"

--- @class RocketController : Controller
--- @field vector Vector2
--- @field path Path
--- @field intent Action? Holds the next scheduled action.

ROCKET_SPEED = 3

function RocketController:__new()

end

--- @param level Level
--- @param actor Actor
function RocketController:act(level, actor)
   local player = level:query(prism.components.PlayerController):first()

   if not self.vector and player then
      self.vector = (player:getPosition() - actor:getPosition()):normalize() * 1
   end

   -- recalculate every time, just don't reset to the PLAYER every time.
   -- the vector will retain for the purposes of pathing.

   -- we want to plot a path that goes effectively forever in this direction. however bresenham needs a destination. we can't just pass `bounds` in as the passability callback, because it will try to route around it or just say "no" when it can't. we could just make it 50 for now and move on. the action will catch it.
   local destination = self.vector * 50
   local x, y = 0, 0
   local dx, dy = destination:decompose()

   -- compute a long-range path following the current vector, in actor-relative
   -- positions.
   local path = prism.Bresenham(x, y, math.floor(dx + 0.5), math.floor(dy + 0.5))

   -- if a path following this vector is still possible,
   local nextMoves = {}
   if path and path.path then
      -- strip the first element
      table.remove(path.path, 1)
      -- no checks -- just GO. let the action work it out.
      for i = 1, math.min(ROCKET_SPEED, #path.path) do
         table.insert(nextMoves, table.remove(path.path, 1))
      end
   end

   -- TODO think about this in an intent world.
   if actor:has(prism.components.Facing) then
      local facing = actor:expect(prism.components.Facing)

      facing:set(self.vector)

      if actor:has(prism.components.Drawable) then
         local drawable = actor:expect(prism.components.Drawable)
         facing:updateDrawable(drawable)
      end
   end

   -- Check for an explosion trigger.
   for entity, relation in pairs(actor:getRelations(prism.relations.SeesRelation)) do
      if entity:has(prism.components.Controller) and entity ~= actor then
         -- supercede the "next" action and just return DIE
         return prism.actions.Die(actor)
      end
   end

   if #nextMoves == 0 then
      return prism.actions.Die(actor)
   else
      if self.intent then
         local intent = self.intent
         self.intent = prism.actions.Fly(actor, nextMoves)
         return intent
      else
         self.intent = prism.actions.Fly(actor, nextMoves)
         return prism.actions.Wait(actor)
      end
   end
end

return RocketController
