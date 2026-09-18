# Feed UI — consumption-only prototype

Placing a pet on your own feed plate opens the Feed panel. Close it with X or
Escape; use the bottom-right Feed Pet button to reopen it. Picking up/removing
the pet closes the panel. Inventory and Feed panels are mutually exclusive.
The authored StarterGui layout is stored in FeedYourPetUI.rbxmx, not generated
at runtime. Close the panel before holding E to pick the pet up.

The Feed button consumes a temporary fixed **1 Food** on the server. No new
config module or balance table was created, per user instruction. Cost comes
from FeedService's snapshot, not a client value. No Feed Level, growth, income,
RNG, explosion, Protection or Revive behavior is implemented in this step.
The panel explicitly labels this as Food consumption only.

FeedService validates loaded data, pet identity/plate ownership, live character,
distance, affordability and cooldown. Per-player monotonic request sequences
reject duplicates, old replays and skipped sequences. Validation/deduction/
sequence advance do not yield, preventing partial interleaved transactions.
Existing Food persistence is reused; no schema change. FeedFoodChanged pushes
the HUD immediately with the same server timestamp ordering as farm/snapshots.

Opt-in two-player Studio memory test:
StudioTestService:ExecuteMultiplayerTestAsync(2, "FeedVerification").
All 21 server checks passed. Nine isolated controller tests using the real UI
asset with mocked input/transport also passed. Physical mouse/touch and rendered
layout still need a Play-session review.
