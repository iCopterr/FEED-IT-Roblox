-- Offline income uses placed pets' base rate (including variants/broken penalty),
-- never the paid x2 multiplier. Uncollected time shares this single cap.
return table.freeze({MinimumSeconds = 10 * 60, MaxSeconds = 24 * 60 * 60, RequestCooldown = 0.5})
