import 'dart:convert';
import 'package:auspex/Models/anime_model.dart';
import 'package:http/http.dart' as http;

class AnimeService {
  final String baseUrl = "https://api.jikan.moe/v4";
  http.Client client = http.Client();
  Future<List<AnimeModel>> getAnimeList() async {
    try {
      print('Making API request to: $baseUrl/anime');
      final response = await client.get(Uri.parse('$baseUrl/seasons/upcoming'));

      print('Response status code: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body.substring(0, 300)}...');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> animeList = data['data'];
        print('First anime synopsis: ${animeList.first['synopsis']}');
        return animeList.map((anime) => AnimeModel.fromJson(anime)).toList();
      } else {
        throw Exception('Failed to load anime list: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAnimeList: $e');
      throw Exception('Failed to load anime list: $e');
    }
  }

  Future<List<AnimeModel>> searchAnime(String query) async {
    try {
      print('Searching anime with query: $query');
      final response = await client.get(
        Uri.parse('$baseUrl/anime?q=${Uri.encodeComponent(query)}'),
      );

      print('Search response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> searchResults = data['data'];

        print('Found ${searchResults.length} results for "$query"');

        return searchResults
            .map((anime) {
              try {
                return AnimeModel.fromJson(anime);
              } catch (e) {
                print('Error parsing search result: $e');
                return null;
              }
            })
            .whereType<AnimeModel>() // Remove null entries
            .toList();
      } else {
        throw Exception('Failed to search anime: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchAnime: $e');
      throw Exception('Failed to search anime: $e');
    }
  }
}
