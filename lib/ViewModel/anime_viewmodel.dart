import 'package:auspex/API_services/firebase_notifications.dart';
import 'package:auspex/Models/anime_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../API_services/api_services.dart';

class AnimeViewModel with ChangeNotifier {
  final AnimeService _animeService = AnimeService();
  List<AnimeModel> _animeList = [];
  bool _isLoading = false;

  List<AnimeModel> get animelist => _animeList;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AnimeModel> _trackedAnime = [];
  List<AnimeModel> get trackedAnime => _trackedAnime;

  get animationController => null;

  Future<void> fetchTopAnime() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Fetching anime list...');
      _animeList = await _animeService.getAnimeList();
      print('Fetched ${_animeList.length} anime');
    } catch (e) {
      _error = e.toString();
      // ignore: avoid_print
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Anime searching function
  Future<void> searchAnime(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      _animeList = (await _animeService.searchAnime(query));
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add anime to Firestore
  Future<void> addTrackedAnime(AnimeModel anime) async {
    try {
      await _firestore
          .collection('trackedAnime')
          .doc(anime.malId.toString())
          .set(anime.toJson());

      await NotificationService.subscribeToAnime(anime.malId.toString());

      _trackedAnime.add(anime);
      notifyListeners();
    } catch (e) {
      print('Error adding anime: $e');
      throw Exception('Failed to add anime to tracking list');
    }
  }

  // Remove anime from Firestore
  Future<void> removeTrackedAnime(AnimeModel anime) async {
    try {
      await _firestore
          .collection('trackedAnime')
          .doc(anime.malId.toString())
          .delete();

      await NotificationService.unsubscribeFromAnime(anime.malId.toString());

      _trackedAnime.removeWhere((element) => element.malId == anime.malId);
      notifyListeners();
    } catch (e) {
      print('Error removing anime: $e');
      throw Exception('Failed to remove anime from tracking list');
    }
  }

  // Fetch tracked anime from Firestore
  Future<void> fetchTrackedAnime() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('trackedAnime').get();

      _trackedAnime.clear();
      for (var doc in snapshot.docs) {
        _trackedAnime.add(AnimeModel.fromJson(doc.data()));
      }
    } catch (e) {
      print('Error fetching tracked anime: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isAnimeTracked(int malId) async {
    try {
      final doc =
          await _firestore
              .collection('trackedAnime')
              .doc(malId.toString())
              .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if anime is tracked: $e');
      return false;
    }
  }

  bool isAnimeInTrackedList(int malId) {
    return _trackedAnime.any((anime) => anime.malId == malId);
  }
}
