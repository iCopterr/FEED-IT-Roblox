# Pet conveyor alpha

The authored Workspace.PetConveyor occupies the reserved center lane, X ±7,
between the two rows of plots. No runtime geometry generator is used. The
server clones the six existing pet templates, never eggs, into transient Offers.

One offer spawns every 4 seconds, travels for 36 seconds and disappears at the
end if unsold. Maximum ten live offers. Server-authoritative rarity selection:

| Rarity | Spawn chance | Money price |
| --- | ---: | ---: |
| Common | 60% | 100 |
| Uncommon | 25% | 1,500 |
| Rare | 10% | 5,000 |
| Epic | 4% | 30,000 |
| Legendary | 0.9% | 100,000 |
| Mythic | 0.1% | 450,000 |

These are temporary alpha values in ConveyorConfig, not GDD egg odds/prices.
Legendary/Mythic retain the existing internal rarity names. Farm/Feed configs
are unchanged. Visible labels show species, colored rarity and purchase price.

Hold E (or gamepad X / touch prompt) near a pet to buy it into your inventory.
The server checks live character, loaded profile, assigned plot, current offer,
expiry, range, funds, cooldown and pending purchase save. No client-selected
price/species/result is trusted. Payment and PetService creation do not yield;
exactly one player can consume an offer. A repeated last purchase returns the
same PetId without charging again. Other sold/expired IDs cannot be purchased.

Paid Money and the new inventory pet save together through DataService; another
conveyor purchase waits for confirmation. Failed saves retry without rollback
or a second reward. Existing leave/shutdown saves include the same profile.
PetId is generated only when purchased, distinct from temporary OfferId. Pets
are unplaced level 0 and never earn while on the conveyor.

Server motion and expiry use a server clock. Client interpolation and moving
authored treads are presentation only. The server computes purchase proximity
from its own timeline. Money HUD updates immediately after purchase.

Assets: PetConveyor.rbxmx, ConveyorPetLabel.rbxmx and ConveyorUI.rbxmx. Re-export
Studio geometry/UI changes to files before Rojo resync. Scripts are file-owned.

Verification: ExecuteMultiplayerTestAsync(2, "ConveyorVerification") passes 37
memory-only checks, including deterministic boundaries for all six rarities,
motion, inventory/payment persistence, replay, competing buyers, offer cap and
actual 36-second expiry. Five isolated client source checks pass using mocked
signals/transport/time. Geometry stays in the reserved lane; no duplicate assets.
The test disables automatic scheduling and explicitly spawns deterministic
offers; ordinary Play enables random timed spawning.

Remaining alpha limitations: physical input/visual feel, automatic spawn pacing
and production DataStore outage/rejoin still need playtesting. New production
profiles still start with zero Money and no onboarding pet; the existing
developer-only Studio starter pet supports alpha testing. This feature does not
grant free pets or change onboarding. No eggs, hatching, stealing or trading.
