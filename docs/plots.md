# Prototype plots

`Workspace.PlayerPlots` contains six prebuilt plot Models: three on each side,
facing an empty 40-stud center lane reserved for a future conveyor. No conveyor
is implemented. Each has a Spawn, an OwnerSign, and a fenced Pen with
five hidden legacy slot references. Plots are 60x60 studs, with 45x33-stud Pens.
Centers are X=-50/+50, Z=-72/0/72, leaving 12 studs between adjacent plots and
the same 40-stud middle lane. Spawn/sign sizes and fence heights are unchanged.
PlotService never generates or clones geometry.

The static Workspace hierarchy is exported in `src/world/PlayerPlots.rbxmx`
and mapped by Rojo. Edit the actual Models in Studio; export edits back to that
asset before changing/rebuilding the file. Rojo does not export Studio edits.
The rest of Workspace remains outside Rojo's ownership.

PlotService assigns one free plot per Player, directs initial spawns and
respawns to it, and releases ownership on PlayerRemoving. Freed plots are
reused. Assignment is session-only; it does not modify saved inventory or
placed-pet records. PlotConfig.PlayerCapacity is six. Set the place's Maximum
Players to 6 in Creator Dashboard as well: MCP cannot write Players.MaxPlayers.
Until that external setting changes, Roblox may admit extra players, who are
rejected when no plot is free. The script limit is not a matchmaking setting.

Server callers can use GetPlot(player), GetSlotCapacity(player), and
GetSlotCFrame(player, index). Slot access requires loaded player data and is
capped at five. Slot markers are layout references, not pets. Placement,
pickup, wandering, and income are subsequent features.

## Verification

Through MCP's Edit context, launch
`StudioTestService:ExecuteMultiplayerTestAsync(2, "PlotVerification")` inside
`task.spawn`, retaining its returned result for polling. The opt-in server
test checks ownership, five-slot capacity, invalid indices, geometry, spawn,
respawn, departing-player cleanup, and freed-plot reuse with a new client.
It ends the test automatically. Ordinary Studio sessions and production do
not execute the verification script's test actions.
