# Handoff — Phase 5 UI polish

Use this document when starting Phase 5 implementation in a fresh chat/agent session.

## Start here

Do not redesign or re-plan Phase 5 from scratch.

Read, in order:

1. `TASKS.md`
2. `docs/UI-POLISH-PLAN.md`
3. `docs/tasks/15-ui-polish-core-hierarchy.md`
4. Current `Profession_capper.xml`
5. Current `Core.lua`
6. Current `Localization.lua`

Then implement **Task 15 only**.

## Repository rules

- Work directly on `master`.
- One implementation task = one commit = one push.
- Do not create a branch or PR unless explicitly requested.
- Update `TASKS.md` in the same implementation commit.
- Preserve WoW 3.3.5 / Lua 5.1 compatibility.
- Run the repository validation workflow.
- Do not mark a task `DONE` until its required manual in-game checks pass.
- Do not combine Task 15 with Task 16.

## Product intent

Profession Capper should feel like a compact decision tool.

The UI's first job is to answer:

> What should I do right now?

The current recommendation should visually dominate. Pricing, material needs, and purchase guidance support that decision. Deeper comparison/route information should be available without turning the default panel into a dashboard.

Avoid:

- nested cards;
- large empty areas;
- decorative gradients;
- unnecessary new windows;
- a custom UI framework;
- changing optimizer logic just to simplify rendering;
- duplicating business logic inside UI code.

## Existing behavior that must survive Task 15

Do not regress:

- Cheapest-now vs Static-guide mode.
- Live orange/yellow recipe comparison logic.
- Per-application and expected-per-skill-up costs.
- Greater/Lesser Essence quantity-aware conversion pricing.
- Inline equivalent-reagent purchase guidance.
- Shift-Right-Click AH search using the recommended purchase form.
- +profession modifier handling.
- Targeted Enchant repeat sessions.
- Remembered Enchant target.
- Auto-confirm existing-enchant replacement.
- Normal non-target batch crafting.
- Static guide fallback.
- TSM stale/missing/no-provider handling.

Task 15 is presentation/hierarchy work around those behaviors.

## Task 15 target

The default panel should approximately read like this:

```text
┌──────────────────────────────────────────────┐
│ Profession Capper                       [×]  │
│ Enchanting 315 / 385 (+10)                  │
│ [Cheapest now]  Static guide      [Compare] │
│──────────────────────────────────────────────│
│ [icon] Enchant Gloves - Greater Agility     │
│        YELLOW · Skill 315 → 320              │
│        Cheapest current skill-up             │
│                                              │
│ ~2g 40s / application   ~3g 20s / skill-up  │
│ Can make 5              current TSM prices  │
│──────────────────────────────────────────────│
│ MATERIALS                                    │
│ [i] Lesser Eternal Essence       0 / 3       │
│     Buy 1× Greater instead · save ~3g   ~9g │
│ [i] Illusion Dust                 2 / 4       │
│     Buy 2                                ~1g │
│──────────────────────────────────────────────│
│ Repeat controls only when relevant           │
│                                              │
│            [ Enchant / Craft ]               │
└──────────────────────────────────────────────┘
```

This is a hierarchy reference, not a pixel-perfect mandate.

## Recommended implementation approach

### 1. Inventory existing render responsibilities

Before editing, identify which existing UI values render:

- title;
- profession progress;
- mode buttons;
- recipe icon/name/status;
- target;
- craft stats;
- craft progress;
- price/freshness;
- cost summary;
- materials;
- repeat controls;
- primary action.

Do not create duplicate state when an existing value can be reformatted/repositioned.

### 2. Restructure XML first

Use `Profession_capper.xml` for stable anchors and named static elements.

Prefer:

- one main backdrop;
- thin separator textures;
- predictable left/right padding;
- simple font strings.

Avoid using XML for dynamic repeated material/comparison rows; those remain Lua-created.

### 3. Centralize layout constants

Current `Core.lua` already contains constants such as material row height and panel offsets.

Task 15 may consolidate presentation constants into one nearby block so later Tasks 16–18 can extend the layout without magic numbers scattered through rendering functions.

Do not create a generic layout framework.

### 4. Make recommendation rendering explicit

Have one clearly identifiable render path for the recommendation block. It should decide text, semantic color, and visibility from existing recommendation/session data.

If useful, extract small pure helpers for:

- difficulty label/color;
- cost-summary strings;
- source/freshness strings;
- material secondary-line strings.

Pure helpers can be unit tested. Blizzard Frame calls do not need fake-frame unit tests.

### 5. Rework material rows

Each row needs enough vertical space for two lines.

Primary line:

- required material name;
- owned / total.

Secondary line:

- purchase recommendation;
- price.

When converted-equivalent purchase guidance exists, make it explicit inline. When no purchase is needed, do not leave fake placeholder text.

Keep existing tooltip and AH-search behavior.

### 6. Dynamic panel height

Compute height from visible sections.

Task 15 should not leave blank space for sections that are hidden. Keep this simple enough that Task 16 can add a comparison section later.

## Definition of done for Task 15 code

Automated validation must pass.

Manual acceptance still required before `DONE`:

- Cheapest-now Enchanting recommendation is readable at a glance.
- Static-guide state is visibly distinct.
- Equivalent Essence purchase hint is visible without hover.
- Long recipe/material names do not collide with counts/costs.
- Missing materials are obvious but not visually dominant over the recommendation.
- Panel height adapts to material count.
- ElvUI enabled does not make buttons/text unreadable.
- Crafting and targeted Enchant flows still work.

If manual testing has not happened yet, commit Task 15 as `IN PROGRESS`, document the pending checks, and do not mark it `DONE`.

## After Task 15

Only after Task 15 is implemented and manually accepted:

- Task 16: inline recipe comparison / why this one.
- Task 17: compact vs expanded detail mode.
- Task 18: polish targeted Enchant repeat presentation.
- Task 19: final visual QA + ElvUI compatibility cleanup.

Do not pull features forward unless Task 15 cannot be implemented correctly without them.

## Ready-to-use implementation instruction

A fresh implementation chat can be given this exact instruction:

> Implement Task 15 from `docs/tasks/15-ui-polish-core-hierarchy.md` on `master`. Treat `docs/UI-POLISH-PLAN.md` and `docs/HANDOFF-PHASE-5-UI.md` as the source of truth. Do not implement Tasks 16–19 yet. Preserve all existing optimizer, equivalent-reagent, Enchant repeat, and auto-confirm behavior. Update `TASKS.md`, run validation before pushing, and keep Task 15 IN PROGRESS until its in-game acceptance checks have actually been performed.
