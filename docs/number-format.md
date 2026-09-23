# Compact numbers

Shared.NumberFormat.Compact formats display amounts with K / M / B / T:
1,250 -> 1.25K; 1,000,000 -> 1M; 2,500,000,000 -> 2.5B; 1e12 -> 1T.
Values above a trillion remain in T (1e15 -> 1000T), per the requested suffixes.
Up to two decimals, trailing zeroes removed, boundary rounding promotes to the
next suffix. Small numbers stay plain; invalid/nonfinite input displays a dash.

Used by the Money HUD, inventory base income, income popups, plot upgrade
prices, conveyor labels/prompts, Feed cost/balance/outcome income,
Revive income/spent Food, and debug currency summary/default amount.
Levels, slot counts, IDs and risk percentages keep their existing formats.

This is display-only. Rounded text never determines payment, Food use, income,
affordability or saved values.

Debug amount input accepts plain/scientific numeric text and case-insensitive
K/M/B/T (for example 10M or 1.5b). NumberFormat.Parse returns the numeric amount;
the existing server still rejects invalid, fractional, negative or oversized
grants. Level inputs remain plain whole numbers.

Verification: require(ServerScriptService.Server.NumberFormatVerification).Run()
in Studio Edit checks boundaries, fractions, negatives, nonfinite
inputs, suffix parsing and the authored debug default.
Synced scripts compile and Rojo build passes. Full visual Play review is pending.
