import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling search functionality and history
class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._();
  
  SearchService._();

  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  /// Loads search history from SharedPreferences
  Future<List<String>> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      return historyJson;
    } catch (e) {
      // Return empty list if there's an error
      return [];
    }
  }

  /// Saves search history to SharedPreferences
  Future<void> saveSearchHistory(List<String> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Adds a search query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = await loadSearchHistory();
    final trimmedQuery = query.trim();
    
    // Remove if already exists
    history.remove(trimmedQuery);
    
    // Add to beginning
    history.insert(0, trimmedQuery);
    
    // Limit to max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    await saveSearchHistory(history);
  }

  /// Removes a search query from history
  Future<void> removeFromHistory(String query) async {
    final history = await loadSearchHistory();
    history.remove(query);
    await saveSearchHistory(history);
  }

  /// Clears all search history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Gets search suggestions based on query
  List<String> getSearchSuggestions(String query, List<String> history) {
    if (query.isEmpty) return [];
    
    final suggestions = <String>{};
    final lowerQuery = query.toLowerCase();
    
    // Add matching history items
    for (final item in history) {
      if (item.toLowerCase().contains(lowerQuery)) {
        suggestions.add(item);
      }
    }
    
    // Add common movie-related suggestions
    final commonSuggestions = [
      'Action',
      'Comedy',
      'Drama',
      'Horror',
      'Romance',
      'Sci-Fi',
      'Thriller',
      'Documentary',
      'Animation',
      'Adventure',
    ];
    
    for (final suggestion in commonSuggestions) {
      if (suggestion.toLowerCase().contains(lowerQuery)) {
        suggestions.add(suggestion);
      }
    }
    
    return suggestions.toList().take(5).toList();
  }

  /// Validates search query
  bool isValidSearchQuery(String query) {
    return query.trim().length >= 2;
  }

  /// Sanitizes search query
  String sanitizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
} 