# Feed UI and outcomes

Stage a carried pet by clicking your plate. The panel opens automatically;
hold E at the plate to reopen it. Hold E never picks up a plate pet.
Pick Up Pet remains inside the panel; Pen pets still use hold-E pickup.
There is no main-screen Feed button.

The panel shows server Food cost, current level, target explosion probability
and the separate 5% Miracle Save chance. Pressing Feed closes the panel;
rejections show an explanation. At level 40 Feed is disabled, but pickup works.

Accepted attempts lift the authored pet clone four studs, accelerate its spin,
then land/grow on success, flash/return on Miracle Save, or burst/fade on
explosion. A screen banner reports actual gained levels/income or recovery
status. Explosions keep their pre-failure records for future Revive; Food stays
spent. Effects cannot modify economy or pet ownership. Other clients receive
visual results only, not private Food/recovery balances.

FeedPanel and FeedBanner are editable StarterGui assets in FeedYourPetUI.rbxmx.
The Feed panel has a centered, larger rotating pet preview in a 560x620 main
card. FoodCards is an attached 240x620 right sidebar, separated by 16 pixels,
with four vertical food choices and a SELECT FOOD heading.
The food choices live in an authored vertical ScrollingFrame with automatic
canvas height and a UIListLayout. Header and footer stay fixed; additional
authored food cards extend the scroll area rather than the sidebar.
Both panels scale and center as one 816x620 group. Feed, pickup, risk and status remain in the
main card; selection and transaction behavior are unchanged.
Popup pages now share a cyan stud-textured header, charcoal body, squared
cards, black outlines, white outlined text and bright action colors. This
theme is authored in the StarterGui assets; controllers only update existing
selection/availability colors. HUD, hotbar and outcome banners are unchanged.
Runtime effects clone the named models in ReplicatedStorage.PetsModel; no world generator.
Duplicate results are suppressed; ambiguous replies can recover the cached
server outcome rather than submit a fresh roll.

Verification (2026-09-18): 55 two-player Studio memory checks pass through
StudioTestService:ExecuteMultiplayerTestAsync(2, "FeedVerification").
Six isolated effect/banner/cleanup/replay checks and five isolated controller
checks pass using the real source/UI with mocked timing or input/transport.
Manual visual/input feel and live DataStore rejoin/outage testing remain pending.
