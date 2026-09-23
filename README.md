# Feed Your Pet

Roblox prototype for validating the core loop:

**Hatch → Place → Earn → Buy Food → Feed → Grow → Risk → Rescue / Base-Level Reset**

Current design updates are in `docs/design-decisions.md`; retired systems are
listed in `docs/retired-features.md`. These supersede historical GDD mechanics.

Read `AGENTS.md`, `PROJECT_STATUS.md`, and the relevant section of
`Feed_Your_Pet_GDD_v0.5.md` before changing a system.

## Repository ownership

- `src/` is the source of truth for Rojo-managed Luau code.
- Roblox Studio is the source of truth for the prototype world and other
  Instances not mapped in `default.project.json`.
- Do not edit a Rojo-managed script in Studio; edit its file under `src/`.

## First-time setup on Windows

1. Install [Rokit](https://github.com/rojo-rbx/rokit#installation).
2. Open PowerShell in this repository and run
   `rokit trust rojo-rbx/rojo`, then `rokit install`.
3. Install the matching Studio plugin with `rojo plugin install`.
4. Open the prototype place in Roblox Studio.
5. Run `rojo serve` in this repository.
6. In Studio, open the Rojo plugin and connect to `localhost:34872`.

If a newly installed `rokit` or `rojo` command is not found, close and reopen
PowerShell once so it reloads your user `PATH`.

The repository pins Rojo in `rokit.toml`, so every Codex session uses the
same compatible CLI version.

## Normal development

Start each session:

```powershell
git status
git pull --ff-only
rokit install
rojo serve
```

End each meaningful session:

1. Update `PROJECT_STATUS.md` with completed work, tests, and the exact next task.
2. Review `git status` and `git diff`.
3. Commit one logical working unit.
4. Push `main` to GitHub.

Only one Codex account or Roblox Studio session should modify this working copy
at a time. Do not hand the PC to the next account with unexplained uncommitted
changes. The Git identity belongs to the repository owner; changing Codex
accounts does not require changing Git configuration.

## Useful commands

```powershell
# Validate the Rojo project and build a local test place.
rojo build default.project.json --output build/FeedYourPet.rbxlx

# Start live synchronization.
rojo serve default.project.json

# Inspect repository state before and after work.
git status
git diff
```
