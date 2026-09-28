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

Owner uploaded all 14 images and provided an Asset Manager screenshot on
2026-09-28. The matching Image asset IDs are recorded as strings in manifest.json.
Use `rbxassetid://` followed by the ID when integrating. No duplicate uploads needed.
IDs were transcribed from the screenshot and checked for completeness/uniqueness;
Roblox loading, moderation and experience permissions have not been verified.
The previous agent upload attempt failed due to missing MCP authentication.

No production UI, config, scripts or models changed. After asset loading
verification, set authored ImageLabels and hide emoji fallbacks; preserve saved
ScreenGui ownership. Icons were visually inspected, but small-size UI rendering
still needs Studio verification. Original emoji behavior remains intact.
