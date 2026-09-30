# Ember Drake — reference-inspired review model

`EmberDrake_Reference.rbxm` is a standalone Studio model. Insert it through
Studio's file/model import workflow. The installed pet template is unchanged.

- 25 BaseParts: 9 colored unions, 10 rig/root anchors, 6 eye/pupil/nostril parts.
- 9 Motor6Ds, 15 welds, Humanoid and Animator. No animations.
- 7,674 union triangles, plus primitive detail geometry.
- Rust body, gold throat and wings, curled tail, narrow amber eyes and fangs.

Verified in Edit mode: internal connections, aligned joints, Torso-only
collision, unanchored parts and part/union-triangle budgets. Serialization
roundtrip preserved union geometry; restored model visually inspected from
both sides and rig checks rerun. RBXM size: 383,651 bytes.

Runtime placement, carrying, growth and performance are not yet tested.
Save the place after inserting. No cloud asset upload is required by this recipe.

Builder: `docs/studio/build-ember-reference.luau`.
Verifier: `docs/studio/verify-ember-reference.luau`.
Both run through Studio MCP in Edit mode. The builder refuses existing names
in Workspace and ServerStorage; inspect partial builds before retrying.
