part of 'swipe_screen.dart';

/// The core Discover swipe handlers (movie + show), split out of
/// swipe_screen.dart. Kept as an extension on _SwipeScreenState (same library
/// via `part`) so the move is verbatim — the only change is setState -> _rebuild
/// (setState is @protected and can't be called from an extension).
extension _SwipeHandlers on _SwipeScreenState {
  /// Handles movie swipe actions:
  /// - Right swipe = Like
  /// - Left swipe = Dislike
  /// - Up swipe = Match (shows match screen with options)
  /// - Down swipe = Skip (neutral action, doesn't like or dislike)
  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    // Allow left, right, up, and down swipes
    if (direction != CardSwiperDirection.left &&
        direction != CardSwiperDirection.right &&
        direction != CardSwiperDirection.top &&
        direction != CardSwiperDirection.bottom) {
      return false; // Block other directions
    }

    Movie? swipedMovie;
    if (previousIndex >= 0) {
      _movieSwipeEpoch++;
      final swipeToken = _movieSwipeEpoch;

      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Prefetch when few cards ahead — throttled so we don't load after every swipe.
      if (currentIndex != null) {
        final totalMovies = movieProvider.filteredMovies.length;
        final remainingMovies = totalMovies - currentIndex;

        if (remainingMovies <= _SwipeScreenState._swipePreloadRemainingThreshold &&
            movieProvider.hasMorePages) {
          final now = DateTime.now();
          if (_lastSwipeTriggeredMoviePreload == null ||
              now.difference(_lastSwipeTriggeredMoviePreload!) >=
                  _SwipeScreenState._swipePreloadMinInterval) {
            _lastSwipeTriggeredMoviePreload = now;
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                final user = authProvider.userData;
                movieProvider.checkAndPreload(
                  user,
                  estimatedRemaining: remainingMovies,
                );
              }
            });
          }
        }
      }

      if (previousIndex < movieProvider.filteredMovies.length) {
        final movie = movieProvider.filteredMovies[previousIndex];
        swipedMovie = movie;

        if (direction == CardSwiperDirection.right) {
          // Like action - add to liked movie
          final likedCountBefore =
              authProvider.userData?.likedMovies.length ?? 0;
          await authProvider.addLikedMovie(movie.id.toString());

          // Track behavior and collaborative filtering
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'like');
          CollaborativeFilteringService().recordUserLike(userId, movie.id);

          // Train adaptive weights, attributing the like to the weight-aligned
          // strategy that surfaced this movie (tracked at scoring time).
          final user = authProvider.userData;
          if (user != null) {
            movieProvider.recordSwipeFeedback(
              movieId: movie.id,
              liked: true,
              user: user,
            );

            // NEW: Online learning - update models in real-time
            OnlineLearningService().recordInteraction(
              userId: user.id,
              movieId: movie.id,
              action: 'like',
            );
          }

          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);

            // One background refresh when crossing 3+ likes, not on every like up to 5.
            if (hasEnoughData &&
                likedCountBefore < 3 &&
                updatedUser.likedMovies.length >= 3) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  movieProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false,
                    backgroundLoad: true,
                  );
                }
              });
            } else {
              _refreshRecommendationsIfNeeded();
            }
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);
        } else if (direction == CardSwiperDirection.left) {
          // Dislike action - add to disliked movies
          await authProvider.addDislikedMovie(movie.id.toString());

          // Track behavior
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'dislike');
          CollaborativeFilteringService().recordUserDislike(userId, movie.id);

          // Train adaptive weights with negative feedback, attributed to the
          // weight-aligned strategy that surfaced this movie.
          final user = authProvider.userData;
          if (user != null) {
            movieProvider.recordSwipeFeedback(
              movieId: movie.id,
              liked: false,
              user: user,
            );

            // NEW: Online learning - update models in real-time
            OnlineLearningService().recordInteraction(
              userId: user.id,
              movieId: movie.id,
              action: 'dislike',
            );
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);
        } else if (direction == CardSwiperDirection.bottom) {
          // Skip action - neutral, doesn't like or dislike
          // Just track the skip behavior for learning
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'skip');

          // NEW: Online learning - record skip for learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: movie.id,
              action: 'skip',
            );
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);
        } else if (direction == CardSwiperDirection.top) {
          // Match action - present the celebration immediately so it reads as
          // one continuous animation with the card flying off. The match screen
          // renders entirely from the in-hand `movie`, so nothing needs to be
          // awaited first; all persistence/tracking runs afterwards in the
          // background and never blocks the transition frame.
          final likedCountBefore =
              authProvider.userData?.likedMovies.length ?? 0;
          final userId = authProvider.userData?.id ?? '';

          if (mounted && swipeToken == _movieSwipeEpoch) {
            showMatchSuccessScreen(
              context,
              movie,
              showAddToWatchlistButton: false,
              autoDismissAfter: const Duration(seconds: 5),
              onContinue: () {
                Navigator.of(context).pop();
              },
              onViewDetails: () async {
                // Preload movie details before navigation
                await MovieCacheService.instance.preloadMovieDetails(movie.id);

                // Replace match success screen with movie detail screen directly
                // This avoids the delay from pop animation + push animation
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    NavigationUtils.fastSlideRoute(
                        MovieDetailScreen(movie: movie)),
                  );
                }
              },
            );
          }

          // Persist + track in the background (off the visible critical path).
          await authProvider.addLikedMovie(movie.id.toString());
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'match');
          CollaborativeFilteringService().recordUserLike(userId, movie.id);

          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);

            if (hasEnoughData &&
                likedCountBefore < 3 &&
                updatedUser.likedMovies.length >= 3) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  movieProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false,
                    backgroundLoad: true,
                  );
                }
              });
            } else {
              _refreshRecommendationsIfNeeded();
            }
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);

          await authProvider.addToWatchlist(movie.id.toString());
        }
      }

      if (!mounted) return true;
      final mpEnd = Provider.of<MovieProvider>(context, listen: false);
      final deckLen = mpEnd.filteredMovies.length;
      if (currentIndex == null &&
          deckLen > 0 &&
          previousIndex == deckLen - 1) {
        mpEnd.beginDiscoverRefillLoading();
      }
    }

    if (mounted && swipedMovie != null) {
      final movieProvider =
          Provider.of<MovieProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      if (direction == CardSwiperDirection.top) {
        // Match swipe: remove immediately (match screen drives UX), drop any
        // pending undo from a previous swipe.
        _clearMoviePendingUndo();
        movieProvider.removeMovie(swipedMovie.id, user: authProvider.userData);
      } else {
        // Remove immediately so the deck advances correctly even on rapid
        // consecutive swipes; keep the swiped card for one-tap UNDO. The
        // keyed CardSwiper remounts onto the new front when the list changes.
        _movieUndoTimer?.cancel();
        movieProvider.removeMovie(swipedMovie.id, user: authProvider.userData);
        _pendingRemovedMovie = swipedMovie;
        _pendingMovieDirection = direction;
        _rebuild(() => _showMovieUndoBanner = true);
        _movieUndoTimer = Timer(const Duration(seconds: 4), () {
          _clearMoviePendingUndo();
        });
      }
    }

    return true; // Allow the swipe to complete
  }

  /// Handles show swipe actions
  Future<bool> _onShowSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (direction != CardSwiperDirection.left &&
        direction != CardSwiperDirection.right &&
        direction != CardSwiperDirection.top &&
        direction != CardSwiperDirection.bottom) {
      return false;
    }

    TvShow? swipedShow;
    if (previousIndex >= 0) {
      _showSwipeEpoch++;
      final swipeToken = _showSwipeEpoch;

      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (currentIndex != null) {
        final totalShows = showProvider.filteredShows.length;
        final remainingShows = totalShows - currentIndex;

        if (remainingShows <= _SwipeScreenState._swipePreloadRemainingThreshold &&
            showProvider.hasMorePages) {
          final now = DateTime.now();
          if (_lastSwipeTriggeredShowPreload == null ||
              now.difference(_lastSwipeTriggeredShowPreload!) >=
                  _SwipeScreenState._swipePreloadMinInterval) {
            _lastSwipeTriggeredShowPreload = now;
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                final user = authProvider.userData;
                showProvider.checkAndPreload(
                  user,
                  estimatedRemaining: remainingShows,
                );
              }
            });
          }
        }
      }

      if (previousIndex < showProvider.filteredShows.length) {
        final show = showProvider.filteredShows[previousIndex];
        swipedShow = show;

        if (direction == CardSwiperDirection.right) {
          // Like action
          final likedCountBefore =
              authProvider.userData?.likedShows.length ?? 0;
          await authProvider.addLikedShow(show.id.toString());

          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'like');
          CollaborativeFilteringService()
              .recordUserLike(userId, showItemId(show.id));

          // NEW: Online learning - update models in real-time
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'like',
            );

            // Train adaptive weights, attributed to the weight-aligned strategy
            // that surfaced this show (tracked at scoring time).
            final user = authProvider.userData;
            if (user != null) {
              showProvider.recordSwipeFeedback(
                showId: show.id,
                liked: true,
                user: user,
              );
            }
          }

          final updatedUserForRefresh = authProvider.userData;
          if (updatedUserForRefresh != null &&
              likedCountBefore < 3 &&
              updatedUserForRefresh.likedShows.length >= 3) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                showProvider.loadPersonalizedRecommendations(
                  updatedUserForRefresh,
                  refresh: false,
                  insertAtFront: false,
                  backgroundLoad: true,
                );
              }
            });
          }
        } else if (direction == CardSwiperDirection.left) {
          // Dislike action
          await authProvider.addDislikedShow(show.id.toString());

          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'dislike');
          CollaborativeFilteringService().recordUserDislike(
              userId, showItemId(show.id));

          // NEW: Online learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'dislike',
            );

            final user = authProvider.userData;
            if (user != null) {
              showProvider.recordSwipeFeedback(
                showId: show.id,
                liked: false,
                user: user,
              );
            }
          }
        } else if (direction == CardSwiperDirection.bottom) {
          // Skip action
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'skip');

          // NEW: Online learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'skip',
            );
          }
        } else if (direction == CardSwiperDirection.top) {
          // Match action - present the celebration immediately so it reads as
          // one continuous animation with the card flying off. The match screen
          // renders entirely from the in-hand `show`, so nothing needs to be
          // awaited first; all persistence/tracking runs afterwards in the
          // background and never blocks the transition frame.
          final likedCountBefore =
              authProvider.userData?.likedShows.length ?? 0;
          final userId = authProvider.userData?.id ?? '';

          if (mounted && swipeToken == _showSwipeEpoch) {
            showShowMatchSuccessScreen(
              context,
              show,
              showAddToWatchlistButton: false,
              autoDismissAfter: const Duration(seconds: 5),
              onContinue: () {
                Navigator.of(context).pop();
              },
              onViewDetails: () async {
                // Replace match success screen with show detail screen directly
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    NavigationUtils.fastSlideRoute(
                        ShowDetailScreen(show: show)),
                  );
                }
              },
            );
          }

          // Persist + track in the background (off the visible critical path).
          await authProvider.addLikedShow(show.id.toString());
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'match');
          CollaborativeFilteringService()
              .recordUserLike(userId, showItemId(show.id));

          // NEW: Online learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'like',
            );

            final user = authProvider.userData;
            if (user != null) {
              showProvider.recordSwipeFeedback(
                showId: show.id,
                liked: true,
                user: user,
              );
            }
          }

          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);

            if (hasEnoughData &&
                likedCountBefore < 3 &&
                updatedUser.likedShows.length >= 3) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  showProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false,
                    backgroundLoad: true,
                  );
                }
              });
            }
          }

          await authProvider.addShowToWatchlist(show.id.toString());
        }
      }

      if (!mounted) return true;
      final spEnd = Provider.of<ShowProvider>(context, listen: false);
      final deckLenShows = spEnd.filteredShows.length;
      if (currentIndex == null &&
          deckLenShows > 0 &&
          previousIndex == deckLenShows - 1) {
        spEnd.beginDiscoverRefillLoading();
      }
    }

    if (mounted && swipedShow != null) {
      final showProvider =
          Provider.of<ShowProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      if (direction == CardSwiperDirection.top) {
        // Match swipe: remove immediately (match screen drives UX).
        _clearShowPendingUndo();
        showProvider.removeShow(swipedShow.id, user: authProvider.userData);
      } else {
        // Remove immediately so the deck advances correctly even on rapid
        // consecutive swipes; keep the swiped card for one-tap UNDO.
        _showUndoTimer?.cancel();
        showProvider.removeShow(swipedShow.id, user: authProvider.userData);
        _pendingRemovedShow = swipedShow;
        _pendingShowDirection = direction;
        _rebuild(() => _showShowUndoBanner = true);
        _showUndoTimer = Timer(const Duration(seconds: 4), () {
          _clearShowPendingUndo();
        });
      }
    }

    return true;
  }
}
