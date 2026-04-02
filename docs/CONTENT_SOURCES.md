# Content sources: strategy and expansion

This document implements the **content sources audit** decisions: what we use today, the chosen near-term strategy, and how a **hybrid second catalog** would be added without breaking Discover, cache, or social (which assume **TMDB numeric IDs**).

---

## 1. Sources in production today

| Source | Role |
|--------|------|
| **TMDB** (`api.themoviedb.org`) | Canonical catalog: movies, TV, search, discover, genres, trending, credits, images, watch providers, trailer metadata. Primary implementation: `lib/services/tmdb_service.dart`. |
| **OMDb** (`omdbapi.com`) | Supplemental **ratings** (IMDb, RT, Metacritic) by **IMDb ID**. `lib/services/omdb_service.dart`. Not used to build the main title lists. |
| **Firebase** | Auth, user data, social graph—not a movie catalog. |
| **YouTube** | Trailer URLs derived from TMDB video keys (`lib/models/video.dart`). |

Recommendation and discovery logic (`movie_discovery_service.dart`, `rec_engine.dart`, providers) **rank and filter TMDB-backed** entities.

---

## 2. Strategy decision (todo: decide-strategy)

**Chosen default: TMDB-only expansion (Strategy A)**

- **Rationale:** Lowest risk, no duplicate titles, no ID reconciliation in the swipe deck, Firestore, or caches. TMDB already exposes many list types (discover, similar, region, keywords, pagination).
- **Actions under this strategy:** Add or tune TMDB-based strategies (more endpoints, locales, dedupe within TMDB lists, smarter pagination/caching)—not a second HTTP catalog.

**Deferred: Hybrid second catalog (Strategy B)**

- Use when product needs feeds TMDB does not cover well (e.g. Trakt-style trending/social lists, editorial lists).
- **Not** the default until there is a concrete product requirement and capacity for mapping + QA.

---

## 3. Hybrid design (todo: if-hybrid): Trakt + TMDB

If Strategy B is approved later, use **one** secondary API first (example: **Trakt**). Others (JustWatch commercial APIs, etc.) follow the same pattern.

### 3.1 Canonical ID

- **`Movie.id` / `TvShow.id` remain TMDB numeric IDs** everywhere in the app (swipe, watchlist keys as strings of that id, `MovieCacheService`, social activity `itemId`).
- Secondary APIs supply **candidates**; items must be **resolved to a TMDB id** before entering the deck or persisted user lists, unless we deliberately scope a separate “import” flow.

### 3.2 Optional ID fields (future model extension)

When implementing hybrid, extend models (or add a small wrapper) so we can trace origin and avoid duplicate fetches:

| Field | Purpose |
|-------|--------|
| `id` (existing) | **TMDB** movie id or TV id (canonical). |
| `imdbId` (existing on `Movie` / `TvShow`) | Bridge to OMDb; also useful for crosswalk. |
| `traktListedId` (new, optional) | Trakt `ids.trakt` or list entry id—**never** use as sole key in user JSON. |
| `traktSlug` (optional) | Human/debug only. |

Implementation note: add fields in `Movie` / `TvShow` **only when** Trakt integration ships; until then, keep a single TMDB pipeline.

### 3.3 Resolution flow (Trakt → TMDB)

1. Trakt returns items with `ids.tmdb` when available—**prefer that** and build `Movie`/`TvShow` from TMDB detail if needed for full cast/images.
2. If Trakt has no TMDB id, resolve via TMDB **find by external id** (`imdb_id`) or search by title+year—then set canonical `id` from TMDB.
3. Discard or quarantine rows that cannot be resolved to a TMDB id if the rest of the app must stay TMDB-only.

### 3.4 Dedupe rules when merging lists

- **Primary key:** TMDB `id` (int for movies, int for TV—keep TV and movie namespaces separate; today shows use `TvShow.id` in show flows).
- When merging Trakt-derived and TMDB-derived lists: **`Map<int, Movie>`** (or show equivalent) keyed by TMDB id; on collision, keep the instance with **richer metadata** (poster, overview, `voteAverage`) or the one from **TMDB** over Trakt stubs.
- **Do not** key user-visible lists by Trakt id.

### 3.5 Adapter layer

- Add a dedicated service (e.g. `trakt_catalog_service.dart`) that returns **`List<Movie>` / `List<TvShow>`** already normalized to TMDB ids, not raw Trakt DTOs in UI.
- Providers (`MovieProvider` / `ShowProvider`) should keep consuming TMDB-shaped models only.

---

## 4. References

- TMDB API: <https://developer.themoviedb.org/docs>
- Trakt API (if Strategy B): <https://trakt.docs.apiary.io/>
- OMDb: <http://www.omdbapi.com/>
