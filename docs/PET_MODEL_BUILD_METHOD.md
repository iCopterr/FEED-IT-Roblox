# Pet model build method for AI agents

Use this guide when creating or remodeling a Roblox creature for **Feed Your Pet**. It describes the actual shape-first method used for the refined Ember Drake. Follow the repository's `AGENTS.md` for source ownership, backups, verification, and handoff.

## How to think before placing parts

1. **Write a silhouette brief.** In one sentence, say what makes the animal identifiable from across the pen. For an Ember Drake: broad haunches, upright neck, long fierce snout, swept horns, two bat wings, and a tapered tail.
2. **Block out proportions.** Set the creature's intended size relative to Chicken and the other species. Mark the ground, body center, shoulder, hip, head, wing tips, and tail tip. Check the front, side, and three-quarter outline before detail work.
3. **Divide the creature into moving groups.** Usually torso, head, four legs, tail, and two wings. Each group gets one rig anchor; visible shapes attach to that anchor. A horn or eye belongs to the head. Wing membrane and ribs belong to the wing.
4. **Spend geometry on recognition.** Put most of the shape budget into the head, major body masses, and signature features. If a creature reads poorly at gameplay distance, enlarge or reshape those forms. Extra tiny spikes will not repair a weak silhouette.

## Choose the Roblox shape deliberately

| Shape needed | Use | Reason |
| --- | --- | --- |
| Invisible root or simple collision body | `Part` | Stable pivot, collision, and rig reference. |
| Beveled torso, skull, neck, thigh, tail section | One tapered `UnionOperation` or durable `MeshPart` per useful section | Gives a rounded, faceted mass without a stack of visible cubes. |
| Straight structural rib, trim, small armor bar | `Part` | A box is already the right shape. |
| Single angular plate or claw | `WedgePart` if it needs only one wedge; otherwise a shaped union/mesh | Simple pieces should stay simple. |
| Horn, fang, dorsal spike, tapered limb | Pointed or tapered union/mesh | A genuine taper reads better than a rectangular stick. |
| Large wing membrane, feather, fin | A thin shaped union/mesh, divided only at real joints or color boundaries | Preserves a clean wing silhouette with few parts. |
| Eye, pupil, nostril, mouth accent | Small separate `Part` or mesh | Allows sharp placement and contrasting color. |
| Magic seam or glowing eye | Existing geometry with `Neon`, plus a restrained light/particle only when needed | Adds emphasis without multiplying decorative parts. |

**Decision rule:** Ask, “Can this visible area be one shaped mass?” If yes, build one mass. Split it only for a joint, material/color boundary, or a silhouette change that cannot be expressed cleanly in one piece. Do not make a creature from thousands of tiny wedges. Also count triangles: a union that cuts BaseParts but greatly increases triangles or saved size is not an optimization.

## Build order

1. Create a disposable model beside a correctly sized neighbor. Back up the installed model first; do not overwrite it during the art trial.
2. Add an invisible `HumanoidRootPart` and simple torso collider. Set the model pivot and ground contact.
3. Build the visible torso, neck, head, and muzzle. Use a few beveled/tapered sections; make their overlaps look intentional.
4. Add legs and feet, then wings and tail. Verify they connect to the body from both sides.
5. Build the face: eye socket or dark surround, narrow iris, pupil, angled brow, shaped jaw, nostrils, and a few fangs where appropriate. The eye angle and skull shape establish “fierce” more reliably than extra glow.
6. Add only the defining horns, plates, feathers, mane, scales, or other creature-specific marks.
7. Apply a compact palette: main color, shadow color, lighter underside/armor color, and one accent/glow color. Use `SmoothPlastic` for most visible geometry. Reserve `Neon` for small focal points.
8. Review at gameplay distance. Remove details that disappear, merge repeated details, and fix the silhouette before final polish.

## Rig and part budget

- Target about **15–40 BaseParts** for a typical small or medium creature. A complex silhouette may justify more; set the budget before building and record the final count.
- Use `Motor6D` between the root/torso and meaningful moving groups. Weld visible details to their group's anchor. Decorative pieces do not each need a motor.
- Keep collision on a simple invisible body shape where possible. Disable collision and touch on decorative geometry; avoid unnecessary mass.
- Preserve a stable `PrimaryPart`, sensible `HipHeight`, aligned joint transforms, and a model that can be saved, reloaded, scaled, carried, placed, and grown.
- Do not create animations unless the task asks for them. A valid rig may still be needed by gameplay systems.

## Verification and iteration

Do **not** declare the model complete because a script ran or the part count is low.

1. Save and reload the actual model. Verify that unions/meshes retain their geometry; a placeholder cube is a failure.
2. Check BasePart count **and** triangle count/serialized size when using unions or meshes.
3. Check pivot, rig connectivity, joint positions, collision, ground contact, and scaling.
4. Inspect front, side, three-quarter, and gameplay views in Studio. Look for disconnected seams, flat faces, weak eyes, wrong proportions, clipping wings, and parts floating above the ground.
5. Remodel visible problems, then recheck the saved model. Run relevant carry/place/growth checks before replacing an installed template.
6. Report the final BasePart count, what was visually checked, and any verification still blocked. Preserve the old model in a backup folder.

## Concrete example

The refined Ember Drake uses shaped unions for large masses, wing sections, horns, and claws, with separate small parts for facial details. Its reference model has **25 BaseParts**: 9 colored unions, 10 rig/root anchors, and 6 eye/pupil/nostril parts. See [`docs/studio/build-ember-reference.luau`](studio/build-ember-reference.luau) and [`assets/pets/ember-drake/README.md`](../assets/pets/ember-drake/README.md).

That example is a *method*, not a fixed creature template. Change anatomy, proportions, and palette to suit the species. Its runtime placement and performance were not proven by the standalone art review; perform those checks for an installed replacement.
