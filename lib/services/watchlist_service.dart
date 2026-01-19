import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_list.dart';
import '../models/movie.dart';

/// Service for managing watchlist lists and organization features
class WatchlistService {
  static WatchlistService? _instance;
  static WatchlistService get instance => _instance ??= WatchlistService._();
  
  WatchlistService._();

  // Storage keys
  static const String _listsKey = 'watchlist_lists';
  static const String _tagsKey = 'watchlist_tags';
  static const String _exportDataKey = 'watchlist_export_data';

  /// Gets all watchlist lists
  Future<List<WatchlistList>> getLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = prefs.getStringList(_listsKey) ?? [];
      
      final lists = <WatchlistList>[];
      for (final listJson in listsJson) {
        try {
          final list = WatchlistList.fromJson(jsonDecode(listJson));
          lists.add(list);
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      // Ensure default list exists
      if (lists.isEmpty || !lists.any((list) => list.isDefault)) {
        final defaultList = WatchlistList(
          id: 'default',
          name: 'All Movies',
          description: 'All your saved movies',
          movieIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDefault: true,
        );
        lists.insert(0, defaultList);
        await _saveLists(lists);
      }
      
      return lists;
    } catch (e) {
      return [];
    }
  }

  /// Saves watchlist lists
  Future<void> _saveLists(List<WatchlistList> lists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = lists.map((list) => jsonEncode(list.toJson())).toList();
      await prefs.setStringList(_listsKey, listsJson);
    } catch (e) {
      // Handle error
    }
  }

  /// Creates a new watchlist list
  Future<WatchlistList?> createList({
    required String name,
    String? description,
    String? color,
  }) async {
    try {
      final lists = await getLists();
      
      // Check if name already exists
      if (lists.any((list) => list.name.toLowerCase() == name.toLowerCase())) {
        return null;
      }
      
      final newList = WatchlistList(
        id: _generateId(),
        name: name,
        description: description,
        color: color,
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      lists.add(newList);
      await _saveLists(lists);
      
      return newList;
    } catch (e) {
      return null;
    }
  }

  /// Updates a watchlist list
  Future<bool> updateList(WatchlistList list) async {
    try {
      final lists = await getLists();
      final index = lists.indexWhere((l) => l.id == list.id);
      
      if (index != -1) {
        lists[index] = list;
        await _saveLists(lists);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a watchlist list
  Future<bool> deleteList(String listId) async {
    try {
      final lists = await getLists();
      final list = lists.firstWhere((l) => l.id == listId);
      
      // Don't allow deletion of default list
      if (list.isDefault) {
        return false;
      }
      
      lists.removeWhere((l) => l.id == listId);
      await _saveLists(lists);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Adds a movie to a list
  Future<bool> addMovieToList(String listId, String movieId) async {
    try {
      final lists = await getLists();
      final index = lists.indexWhere((l) => l.id == listId);
      
      if (index != -1) {
        final updatedList = lists[index].addMovie(movieId);
        lists[index] = updatedList;
        await _saveLists(lists);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Removes a movie from a list
  Future<bool> removeMovieFromList(String listId, String movieId) async {
    try {
      final lists = await getLists();
      final index = lists.indexWhere((l) => l.id == listId);
      
      if (index != -1) {
        final updatedList = lists[index].removeMovie(movieId);
        lists[index] = updatedList;
        await _saveLists(lists);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gets movies in a specific list
  Future<List<String>> getMoviesInList(String listId) async {
    try {
      final lists = await getLists();
      final list = lists.firstWhere((l) => l.id == listId);
      return list.movieIds;
    } catch (e) {
      return [];
    }
  }

  /// Gets lists containing a specific movie
  Future<List<WatchlistList>> getListsContainingMovie(String movieId) async {
    try {
      final lists = await getLists();
      return lists.where((list) => list.containsMovie(movieId)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets tags for movies
  Future<Map<String, List<String>>> getMovieTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tagsJson = prefs.getString(_tagsKey);
      
      if (tagsJson != null) {
        final tagsMap = Map<String, dynamic>.from(jsonDecode(tagsJson));
        return tagsMap.map((key, value) => MapEntry(key, List<String>.from(value)));
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Adds a tag to a movie
  Future<bool> addTagToMovie(String movieId, String tag) async {
    try {
      final tags = await getMovieTags();
      
      if (!tags.containsKey(movieId)) {
        tags[movieId] = [];
      }
      
      if (!tags[movieId]!.contains(tag)) {
        tags[movieId]!.add(tag);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tagsKey, jsonEncode(tags));
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Removes a tag from a movie
  Future<bool> removeTagFromMovie(String movieId, String tag) async {
    try {
      final tags = await getMovieTags();
      
      if (tags.containsKey(movieId) && tags[movieId]!.contains(tag)) {
        tags[movieId]!.remove(tag);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tagsKey, jsonEncode(tags));
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gets all unique tags
  Future<List<String>> getAllTags() async {
    try {
      final tags = await getMovieTags();
      final allTags = <String>{};
      
      for (final movieTags in tags.values) {
        allTags.addAll(movieTags);
      }
      
      return allTags.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  /// Gets movies with a specific tag
  Future<List<String>> getMoviesWithTag(String tag) async {
    try {
      final tags = await getMovieTags();
      final movies = <String>[];
      
      for (final entry in tags.entries) {
        if (entry.value.contains(tag)) {
          movies.add(entry.key);
        }
      }
      
      return movies;
    } catch (e) {
      return [];
    }
  }

  /// Exports watchlist data
  Future<String> exportWatchlistData() async {
    try {
      final lists = await getLists();
      final tags = await getMovieTags();
      
      final exportData = {
        'lists': lists.map((list) => list.toJson()).toList(),
        'tags': tags,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final jsonString = jsonEncode(exportData);
      
      // Save export data for potential import
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_exportDataKey, jsonString);
      
      return jsonString;
    } catch (e) {
      return '';
    }
  }

  /// Imports watchlist data
  Future<bool> importWatchlistData(String jsonData) async {
    try {
      final importData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Import lists
      if (importData.containsKey('lists')) {
        final listsJson = importData['lists'] as List;
        final lists = listsJson.map((json) => WatchlistList.fromJson(json)).toList();
        await _saveLists(lists);
      }
      
      // Import tags
      if (importData.containsKey('tags')) {
        final tags = Map<String, List<String>>.from(importData['tags']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tagsKey, jsonEncode(tags));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets export data
  Future<String?> getExportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_exportDataKey);
    } catch (e) {
      return null;
    }
  }

  /// Clears all watchlist data
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_listsKey);
      await prefs.remove(_tagsKey);
      await prefs.remove(_exportDataKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets watchlist statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final lists = await getLists();
      final tags = await getMovieTags();
      
      final totalMovies = lists.fold<int>(0, (sum, list) => sum + list.movieCount);
      final uniqueMovies = <String>{};
      
      for (final list in lists) {
        uniqueMovies.addAll(list.movieIds);
      }
      
      final totalTags = tags.values.fold<int>(0, (sum, movieTags) => sum + movieTags.length);
      final uniqueTags = <String>{};
      
      for (final movieTags in tags.values) {
        uniqueTags.addAll(movieTags);
      }
      
      return {
        'totalLists': lists.length,
        'totalMovies': totalMovies,
        'uniqueMovies': uniqueMovies.length,
        'totalTags': totalTags,
        'uniqueTags': uniqueTags.length,
        'mostUsedTags': _getMostUsedTags(tags),
        'largestList': _getLargestList(lists),
      };
    } catch (e) {
      return {};
    }
  }

  /// Gets most used tags
  List<MapEntry<String, int>> _getMostUsedTags(Map<String, List<String>> tags) {
    final tagCounts = <String, int>{};
    
    for (final movieTags in tags.values) {
      for (final tag in movieTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTags.take(5).toList();
  }

  /// Gets largest list
  WatchlistList? _getLargestList(List<WatchlistList> lists) {
    if (lists.isEmpty) return null;
    
    return lists.reduce((a, b) => a.movieCount > b.movieCount ? a : b);
  }

  /// Generates a unique ID
  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Searches lists by name
  Future<List<WatchlistList>> searchLists(String query) async {
    try {
      final lists = await getLists();
      final lowercaseQuery = query.toLowerCase();
      
      return lists.where((list) {
        return list.name.toLowerCase().contains(lowercaseQuery) ||
               (list.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets lists sorted by different criteria
  Future<List<WatchlistList>> getListsSorted(String sortBy) async {
    try {
      final lists = await getLists();
      
      switch (sortBy) {
        case 'name':
          lists.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'date_created':
          lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'date_updated':
          lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case 'movie_count':
          lists.sort((a, b) => b.movieCount.compareTo(a.movieCount));
          break;
        default:
          // Keep original order
          break;
      }
      
      return lists;
    } catch (e) {
      return [];
    }
  }
} 