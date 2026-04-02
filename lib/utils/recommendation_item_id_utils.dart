/// Utility to namespace recommendation item IDs so movie and TV-show signals
/// don't collide when they share the same underlying CF/MF/behavior storage.
///
/// TMDB IDs are integers but can overlap across media types, so we offset
/// show IDs when calling shared services (CF/MF/behavior/online-learning).
library recommendation_item_id_utils;

const int kShowItemIdOffset = 1000000000;

int movieItemId(int movieId) => movieId;

int showItemId(int showId) => showId + kShowItemIdOffset;

