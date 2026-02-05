---@class Damage : Action
local Damage = prism.Action:extend("Damage")

local DamageAmount = prism.Target():isType("number")
local DamageTarget = prism.Target(prism.components.Health)
local IsCrit = prism.Target():isType("boolean")
-- TODO damage types -- could be fire, poison, electrical(?)
-- TODO push damage? pierching damge?

Damage.targets = { DamageTarget, DamageAmount, IsCrit }

-- will need to have some sort of attacker requirement here
Damage.requiredComponents = {}

function Damage:canPerform(level, target, amount, crit)
   if amount <= 0 then
      return false, "Damage amount must be greater than 0, not " .. amount
   end

   return true
end

local function triggerGasJet(level, source, target)
   local emitter = target:expect(prism.components.GasEmitter)

   if emitter.disabled then
      local sourcePos = source:getPosition()
      local targetPos = target:getPosition()

      -- Direction vectors for each rotation (0=right, 1=down, 2=left, 3=up)
      local directionVectors = {
         prism.Vector2.RIGHT, -- 0
         prism.Vector2.DOWN,  -- 1
         prism.Vector2.LEFT,  -- 2
         prism.Vector2.UP     -- 3
      }

      -- Check which directions are blocked by impermeable entities
      local function isDirectionBlocked(dir)
         local jetDirection = directionVectors[dir + 1]
         local checkPos = targetPos + jetDirection

         if not level:inBounds(checkPos:decompose()) then
            return true
         end

         local cell = level:getCell(checkPos:decompose())
         if cell:has(prism.components.Impermeable) then
            return true
         end

         local entities = level:query():at(checkPos:decompose()):gather()
         for _, entity in ipairs(entities) do
            if entity:has(prism.components.Impermeable) then
               return true
            end
         end

         return false
      end

      -- Calculate initial direction from source to target
      local directionVector = targetPos - sourcePos
      local angle = math.atan2(directionVector.y, directionVector.x)
      local degrees = math.deg(angle)
      if degrees < 0 then degrees = degrees + 360 end

      -- Map angle to initial direction
      local direction
      if degrees >= 315 or degrees < 45 then
         direction = 2 -- right
      elseif degrees >= 45 and degrees < 135 then
         direction = 1 -- down
      elseif degrees >= 135 and degrees < 225 then
         direction = 0 -- left
      else             -- 225 to 315
         direction = 3 -- up
      end

      -- If initial direction is blocked, use position comparison to pick direction
      if isDirectionBlocked(direction) then
         -- Try directions based on source position relative to target
         local candidateDirections = {}

         -- For N/S blocked pipes - choose E/W based on source position
         if isDirectionBlocked(3) and isDirectionBlocked(1) then -- up and down blocked
            if sourcePos.x > targetPos.x then
               table.insert(candidateDirections, 0)              -- go east (away from source)
            elseif sourcePos.x < targetPos.x then
               table.insert(candidateDirections, 2)              -- go west (away from source)
            else                                                 -- sourcePos.x == targetPos.x, shooting from N/S
               if sourcePos.y > targetPos.y then
                  table.insert(candidateDirections, 1)           -- go south (away from source)
               else
                  table.insert(candidateDirections, 3)           -- go north (away from source)
               end
            end
         end

         -- For E/W blocked pipes - choose N/S based on source position
         if isDirectionBlocked(0) and isDirectionBlocked(2) then -- right and left blocked
            if sourcePos.y > targetPos.y then
               table.insert(candidateDirections, 3)              -- go north (away from source)
            else
               table.insert(candidateDirections, 1)              -- go south (away from source)
            end
         end

         -- Try candidate directions first, then fall back to any available
         for _, dir in ipairs(candidateDirections) do
            if not isDirectionBlocked(dir) then
               direction = dir
               break
            end
         end

         -- If no candidate worked, just find any unblocked direction
         if isDirectionBlocked(direction) then
            for dir = 0, 3 do
               if not isDirectionBlocked(dir) then
                  direction = dir
                  break
               end
            end
         end
      end

      emitter.direction = direction

      emitter.disabled = false
      level:yield(prism.messages.AnimationMessage({
         animation = spectrum.animations.Jet(
            target,
            0.1,
            GAS_TYPES["smoke"].index,
            GAS_TYPES["smoke"].bgFading,
            5,
            direction
         ),
         actor = target,
         blocking = true,
         skippable = false
      }))
   end
end

function Damage:perform(level, target, amount, crit)
   local healthC = target:expect(prism.components.Health)

   healthC.value = healthC.value - amount

   if healthC.value <= 0 then
      local die = prism.actions.Die(target)
      level:tryPerform(die)
   end

   if target:has(prism.components.GasEmitter) then
      triggerGasJet(level, self.owner, target)
   end

   if target:has(prism.components.SparkOnDamage) then
      local direction = prism.Vector2(level.RNG:random(-1, 1), level.RNG:random(-1, 1))

      local magnitude = level.RNG:random(2, 5)
      level:yield(prism.messages.OverlayAnimationMessage({
         animation = spectrum.animations.TextMove(
            target,
            "!",
            direction,
            0.5, prism.Color4.BLACK, prism.Color4.LIME, { worldPos = true, actorOffset = direction }
         ),
         actor = target,
         blocking = false,
         skippable = false
      }))
   end

   -- Show different text for critical hits
   if crit then
      -- Critical: Show "CRIT" text above the damage number
      level:yield(prism.messages.OverlayAnimationMessage({
         animation = spectrum.animations.TextMove(
            target,
            "CRIT",
            prism.Vector2.UP * 3,
            0.6, prism.Color4.WHITE, prism.Color4.RED,
            { worldPos = true, actorOffset = prism.Vector2(-2, -3), layer = 700 }
         ),
         actor = target,
         blocking = false,
         skippable = false
      }))
      -- Show damage number below the CRIT text (same style as normal damage)
      level:yield(prism.messages.OverlayAnimationMessage({
         animation = spectrum.animations.TextMove(
            target,
            "-" .. tostring(amount),
            prism.Vector2.UP * 2,
            0.5, prism.Color4.WHITE, prism.Color4.RED, { worldPos = true, actorOffset = prism.Vector2(-2, -2) }
         ),
         actor = target,
         blocking = false,
         skippable = false
      }))
   else
      -- Normal: White text on red background
      level:yield(prism.messages.OverlayAnimationMessage({
         animation = spectrum.animations.TextMove(
            target,
            "-" .. tostring(amount),
            prism.Vector2.UP * 2,
            0.5, prism.Color4.WHITE, prism.Color4.RED, { worldPos = true, actorOffset = prism.Vector2(-2, -2) }
         ),
         actor = target,
         blocking = false,
         skippable = false
      }))
   end
end

return Damage
