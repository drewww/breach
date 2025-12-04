local FollowerBotController = prism.components.Controller:extend("FollowerBotController")
FollowerBotController.name = "FollowerBotController"

function FollowerBotController:__new()
   local wait = prism.behaviors.WaitBehavior()

   -- what is the flow here ...
   -- move to leader's offset target
   -- pick a new leader
   -- (FUTURE) if no leader, a fallback random waypoint behavior model. I think that means a selector for the first two and then another layer of nodes around the normal waypoint pattern that's "sub" that
   -- so that's two new behaviors:
   --    SelectLeaderBehavior
   --    MoveToLeaderOffset
   local selectLeader = prism.behaviors.SelectLeaderBehavior()
   local setDestinationToLeader = prism.behaviors.SetDestinationToLeader()
   local destinationMove = prism.behaviors.DestinationMoveBehavior()


   self.root = prism.BehaviorTree.Root({ selectLeader, setDestinationToLeader, destinationMove, wait })
end

--- @param level Level
--- @param actor Actor
function FollowerBotController:act(level, actor)
   return self.root:run(level, actor, self)
end

return FollowerBotController
