/// Riverpod providers for TMDB metadata services.
///
/// Manages the API key lifecycle (persisted via SharedPreferences),
/// the TMDB client instance, and the metadata fetch orchestrator.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:flutter_video/features/metadata/metadata_service.dart';
import 'package:flutter_video/features/metadata/tmdb_client.dart';

const _tmdbApiKeyPref = 'tmdb_api_key';

// API Key

/// Holds the TMDB API key. Initialized from SharedPreferences on app start.
class TmdbApiKeyNotifier extends Notifier<String> {
  @override
  String build() => ''; // Empty until loaded from prefs

  /// Load the saved API key from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_tmdbApiKeyPref) ?? '';
  }

  /// Save a new API key.
  Future<void> save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tmdbApiKeyPref, key.trim());
    state = key.trim();
  }
}

final tmdbApiKeyProvider =
    NotifierProvider<TmdbApiKeyNotifier, String>(TmdbApiKeyNotifier.new);

const _tmdbApiBaseUrlPref = 'tmdb_api_base_url';
const String kDefaultTmdbApiBaseUrl = 'https://api.themoviedb.org/3';

// Base URL

/// Holds the custom TMDB API base URL. Initialized from SharedPreferences on app start.
class TmdbApiBaseUrlNotifier extends Notifier<String> {
  @override
  String build() => kDefaultTmdbApiBaseUrl;

  /// Load the saved custom URL from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_tmdbApiBaseUrlPref) ?? kDefaultTmdbApiBaseUrl;
  }

  /// Save a new custom URL.
  Future<void> save(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), ''); // strip trailing slashes
    final targetUrl = cleanUrl.isEmpty ? kDefaultTmdbApiBaseUrl : cleanUrl;
    await prefs.setString(_tmdbApiBaseUrlPref, targetUrl);
    state = targetUrl;
  }
}

final tmdbApiBaseUrlProvider =
    NotifierProvider<TmdbApiBaseUrlNotifier, String>(TmdbApiBaseUrlNotifier.new);

// TMDB Client

/// Provides a TmdbClient instance when an API key is available.
/// Returns null if no API key is set.
final tmdbClientProvider = Provider<TmdbClient?>((ref) {
  final apiKey = ref.watch(tmdbApiKeyProvider);
  if (apiKey.isEmpty) return null;
  final baseUrl = ref.watch(tmdbApiBaseUrlProvider);
  return TmdbClient(apiKey: apiKey, baseUrl: baseUrl);
});

// Metadata Service

/// Provides the metadata orchestration service.
/// Returns null if no TMDB client is available.
final metadataServiceProvider = Provider<MetadataService?>((ref) {
  final client = ref.watch(tmdbClientProvider);
  if (client == null) return null;

  final db = ref.watch(databaseProvider);
  final service = MetadataService(db: db, client: client);

  ref.onDispose(() => service.dispose());
  return service;
});

// Fetch Status

/// Tracks the current state of metadata fetching for the UI.
class MetadataFetchNotifier extends Notifier<MetadataFetchStatus> {
  StreamSubscription<MetadataFetchStatus>? _sub;

  @override
  MetadataFetchStatus build() {
    // Listen to the metadata service's status stream
    final service = ref.watch(metadataServiceProvider);
    _sub?.cancel();

    if (service != null) {
      _sub = service.statusStream.listen((status) {
        state = status;
      });

      ref.onDispose(() => _sub?.cancel());
    }

    return MetadataFetchStatus.idle;
  }

  /// Trigger a fetch of all unmatched files.
  Future<void> fetchAll() async {
    final service = ref.read(metadataServiceProvider);
    if (service == null) {
      state = const MetadataFetchStatus(
        errorMessage: 'No TMDB API key configured. Add one in Settings.',
      );
      return;
    }
    await service.fetchAllUnmatched();
  }

  /// Clear all metadata and re-fetch.
  Future<void> refreshAll() async {
    final service = ref.read(metadataServiceProvider);
    if (service == null) {
      state = const MetadataFetchStatus(
        errorMessage: 'No TMDB API key configured. Add one in Settings.',
      );
      return;
    }
    await service.refreshAll();
  }
}

final metadataFetchProvider =
    NotifierProvider<MetadataFetchNotifier, MetadataFetchStatus>(
        MetadataFetchNotifier.new);
