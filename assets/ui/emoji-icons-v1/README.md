# Emoji replacement icons — 2026-09-28

Generated with built-in image_gen. Exact prompts and emoji/file mappings are
in manifest.json. Fourteen independent transparent PNGs, not an atlas.

| Use | Emoji | File |
| --- | --- | --- |
| basic-food | 🍗 | basic-food.png |
| fresh-food | 🍎 | fresh-food.png |
| hearty-food | 🥩 | hearty-food.png |
| fortified-food | 🥘 | fortified-food.png |
| gourmet-food | 🍱 | gourmet-food.png |
| enchanted-food | 🔮 | enchanted-food.png |
| royal-food | 🍰 | royal-food.png |
| blessed-food | ✨ | blessed-food.png |
| revive-charm | 💖 | revive-charm.png |
| money | 💵 | money.png |
| egg | 🥚 | egg.png |
| pets | 🐾 | pets.png |
| index | 📖 | index.png |
| empty-food | 🍽️ | empty-food.png |

Audited filesystem FoodConfig, ReviveConfig, UI controllers and saved ScreenGuis.
Studio live audit timed out; this list describes saved project sources.
Retired shield/protection marker in FeedEffects is excluded. Token UI is retired.
Empty plate is a merchant fallback, not another purchasable item.

## Upload/handoff

Upload attempted for Basic Food via Roblox MCP upload_decal targeting owner
5250447342. Tool rejected it: No auth configured for asset upload. No assets
were created and no asset IDs are claimed. Configure upload authentication in
the MCP server locally (prefer a scoped Open Cloud key with required asset-write
permission); never paste secrets in chat. Reconnect Studio for live checks.
Alternatively manually upload the PNGs in Creator Dashboard and supply IDs.

No production UI, config, scripts or models changed. After upload approval and
verification, set authored ImageLabels and hide emoji fallbacks; preserve saved
ScreenGui ownership. Icons were visually inspected, but small-size UI rendering
still needs Studio verification. Original emoji behavior remains intact.
