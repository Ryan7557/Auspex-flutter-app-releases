import 'package:cloud_firestore/cloud_firestore.dart';

class AnimeModel {
  final int malId;
  final String title;
  final String? synopsis;
  final String imageUrl;
  final DateTime? nextEpisodeDate;

  AnimeModel({
    required this.malId,
    required this.title,
    this.synopsis,
    required this.imageUrl,
    this.nextEpisodeDate,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    try {
      return AnimeModel(
        malId: json['mal_id'] ?? 0,
        title: json['title'] ?? 'Uknown',
        synopsis: json['synopsis'] ?? 'No synopsis available.',
        nextEpisodeDate:
            json['nextEpisodeDate'] != null
                ? (json['nextEpisodeDate'] as Timestamp).toDate()
                : null,
        imageUrl:
            json['images']?['jpg']['image_url'] ??
            'https://via.placeholder.com/150',
      );
    } catch (e) {
      print('Error parsing anime: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'mal_id': malId,
      'title': title,
      'synopsis': synopsis,
      'image_url': imageUrl,
      'nextEpisodeDate':
          nextEpisodeDate != null ? Timestamp.fromDate(nextEpisodeDate!) : null,
    };
  }
}
