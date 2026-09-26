# First-time tutorial

New profiles start with exactly 5,000 Money and `Settings.TutorialStep=BuyEgg`.
The initial DataStore record contains both values; no repeatable claim remote
or balance top-up exists. Older saves keep their Money and Settings unchanged
and are not automatically enrolled. This uses the existing Settings map
(current schema v10 adds ReviveCharges separately). The old developer-only Studio pet is
suppressed for tutorial profiles (its explicitly named verification still works).

## Guided flow

1. Buy one Basic Egg from the normal conveyor for 5,000 Money.
2. Hold it and click inside the owner's pen to place it.
3. Wait the normal hatch time and press E beside the ready egg.
4. Hold the hatched pet and place it in the pen to earn Money.
5. Reach **at least** 100 Money, then click the Merchant teleport button.
6. Open the merchant with E and buy one Basic Food serving for 100 Money.
7. Close the food shop with X, then click Base, hold E to pick up the placed pet,
   and click the feed plate. If another control already closed the shop (or its
   ScreenGui is disabled), the close hint is skipped automatically.
8. Hold E to open Feed UI, select Basic Food, and Feed. An accepted normal Feed
   completes the tutorial; no result override or additional reward is granted.

The first egg's UID and hatched PetId are tracked, not an arbitrary inventory
position. Failed purchases/actions cannot advance progress. Removing/re-equipping
the item, dying, or rejoining leads to context-sensitive hotbar/inventory guidance.
Placed eggs keep their original timer. Remote hatch and other legitimate existing
convenience actions also count. Earlier legitimate food purchases are remembered,
so their food is not charged twice. The tutorial guides but does not disable normal
gameplay; only spending the initial egg budget on merchant food is rejected while
the player is still on BuyEgg, to avoid a no-pet/no-income softlock.

## Implementation

- TutorialConfig centralizes starting Money, target, guide cadence and arrow budget.
- TutorialProgress contains server-only, non-yielding milestone updates. Egg,
  merchant, travel and feed services call it after successful validation. Egg,
  food and feed progress shares the existing transaction save. TutorialService
  reconciles placement/income and saves other transitions with retry backoff.
- Persistent state: TutorialStep, TutorialEggUid, TutorialPetId and
  TutorialBoughtFood inside Settings. Copies survive the normal schema clone.
  Player attributes are display-only and never accepted as authoritative input.
- StarterGui.TutorialUI is authored in `src/ui/TutorialUI.rbxmx`; all hint, focus
  border and pointer Instances exist there, not in runtime constructor code.
- ReplicatedStorage.TutorialArrow is an authored two-wedge triangle. A client-only
  pool of at most 24 models (48 non-interactive parts) moves toward the current
  objective with a pink/yellow gradient. Originals are never modified. This is a
  direction trail, not obstacle-aware pathfinding. No pet preview models are added.
- TutorialController chooses context-specific targets and animates the trail and
  focus at up to 30Hz. Closing/completing hides presentation; completion destroys
  arrow clones. Already-completed profiles do not repeat the completion banner.

## Verification

Use a separate idle-context deferred Studio launch:

```lua
game:SetAttribute("TutorialReviewResult", nil)
task.defer(function()
    local ok, result = pcall(function()
        return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "TutorialVerification")
    end)
    game:SetAttribute("TutorialReviewResult", game:GetService("HttpService"):JSONEncode({ok=ok, result=result}))
end)
```

Read the result in a later command. The memory-only suite covers real conveyor
purchase, placement, timed hatch, normal income, both travel actions, one Basic
purchase, hold pickup, feeding/replay, copied-save resume/completion, legacy
non-enrollment, independent players, client targets, and arrow safety/cleanup.
It advances the test balance to 99 before a real Money tick to avoid grinding;
it does not change the hatch timer or force a hatch/feed result.

Existing published saves will not show this tutorial. Use a fresh account/profile
for live testing; do not delete or reset existing saves without owner permission.
Actual published-server rejoin and touch/controller feel still need playtesting.

TutorialVerification passed all 46 server/client-report checks after the one-serving
purchase change, including X guidance before Base and skipping when another control
hides the shop or disables its ScreenGui. FoodShopVerification passed 78 checks.
Rojo build and syntax/diff checks pass. Published persistence and mobile feel are
still separate deployment/playtest checks.
