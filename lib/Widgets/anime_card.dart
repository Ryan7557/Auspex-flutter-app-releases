import 'package:auspex/Models/anime_model.dart';
import 'package:auspex/Views/details_page.dart';
import 'package:auspex/Views/tracked_anime_details.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class BaseAnimeCard extends StatelessWidget {
  final AnimeModel anime;
  final Animation<double> animation;

  const BaseAnimeCard({
    super.key,
    required this.anime,
    required this.animation,
  });

  void onCardTap(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation.drive(
        Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: () => onCardTap(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'anime_${anime.malId}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8.0),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: anime.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error loading image',
                                    style: TextStyle(
                                      color: Colors.red[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    anime.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: GoogleFonts.vt323().fontFamily,
                      fontSize: 20,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimeCard extends BaseAnimeCard {
  const AnimeCard({super.key, required super.anime, required super.animation});

  @override
  void onCardTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnimeDetailsPage(anime: anime)),
    );
  }
}

class TrackedAnimeCard extends BaseAnimeCard {
  const TrackedAnimeCard({
    super.key,
    required super.anime,
    required super.animation,
  });

  @override
  void onCardTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackedAnimeDetailsPage(anime: anime),
      ),
    );
  }
}
