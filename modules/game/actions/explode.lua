local ExplodeTarget = prism.Target():isVector2()
local AOE = prism.Target():isType("number")

---@class Explode : Action
local Explode = prism.Action:extend("Explode")

Explode.targets = { ExplodeTarget, AOE }

function Explode:canPerform()
   return true
end

function Explode:perform(level, center, range)
   -- custom AOE here, since level:getAOE only returns actors not cells.
   local affectedCells = {}

   -- Use nested for loops to check all positions within the potential range
   for x = center.x - range, center.x + range + 1 do
      for y = center.y - range, center.y + range + 1 do
         -- Check if position is within bounds
         if level:inBounds(x, y) then
            -- Calculate euclidean distance
            local dx = x - center.x
            local dy = y - center.y
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Include cell if within range
            if distance <= range then
               table.insert(affectedCells, prism.Vector2(x, y))
            end
         end
      end
   end

   for _, pos in ipairs(affectedCells) do
      local actor = level:query(prism.components.Health):at(pos:decompose()):first()

      level:tryPerform(prism.actions.Damage(self.owner, actor, 5))

      local cell = level:getCell(pos:decompose())

      -- TODO check that there is a permeable path from source to destination here. This currently goes through walls.
      if not cell:has(prism.components.Impermeable) then
         local smoke = prism.actors.Smoke(1)
         level:addActor(smoke, pos:decompose())
      end
   end

   level:yield(prism.messages.AnimationMessage({
      animation = spectrum.animations.Explosion(center, 1.5, 2, prism.Color4.DARKGREY),
      blocking = false,
      skippable = false
   }))

   return true
end

return Explode
