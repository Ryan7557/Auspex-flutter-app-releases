import 'package:auspex/API_services/firebase_notifications.dart';
import 'package:auspex/Models/anime_model.dart';
import 'package:auspex/ViewModel/anime_viewmodel.dart';
import 'package:auspex/Widgets/image_section.dart';
import 'package:auspex/Widgets/title_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AnimeDetailsPage extends StatelessWidget {
  const AnimeDetailsPage({super.key, required this.anime});
  final AnimeModel anime;

  // Memoize styles and dimensions
  static const _imageSize = Size(200, 300);
  static const _buttonSize = Size(200, 45);
  static const _contentPadding = EdgeInsets.all(16.0);
  static const _snackBarWidth = 350.0;
  static const _snackBarDuration = Duration(seconds: 2);

  static final _titleStyle = GoogleFonts.vt323(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static final _synopsisStyle = GoogleFonts.vt323(fontSize: 16, height: 1.5);

  Future<void> _handleTrackButtonPress(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final viewModel = context.read<AnimeViewModel>();

      // Check if anime is already tracked
      if (await viewModel.isAnimeTracked(anime.malId)) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          '${anime.title} is already being tracked',
          Colors.orange,
        );
        return;
      }

      await NotificationService.startTrackingFromToday({
        'malId': anime.malId,
        'title': anime.title,
        'imageUrl': anime.imageUrl,
        'synopsis': anime.synopsis,
      });

      await viewModel.addTrackedAnime(anime);

      if (!context.mounted) return;
      _showSnackBar(
        context,
        '${anime.title} added to tracking list',
        Colors.green,
      );
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('Error tracking anime: $e\n$stackTrace');
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Failed to add ${anime.title} to tracking list',
        Colors.red,
      );
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _titleStyle.copyWith(fontSize: 16)),
        backgroundColor: backgroundColor,
        duration: _snackBarDuration,
        behavior: SnackBarBehavior.floating,
        width: _snackBarWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          anime.title,
          style: _titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const SizedBox(height: 24),
                  _buildImageSection(),
                  const SizedBox(height: 24),
                  _buildTitleAndButton(context),
                  const SizedBox(height: 24),
                  _buildSynopsisCard(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Hero(
        tag: 'anime_${anime.malId}',
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox.fromSize(
            size: _imageSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageSection(imageUrl: anime.imageUrl, memCacheWidth: 400),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndButton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TitleSection(title: anime.title),
                const SizedBox(height: 16),
                SizedBox.fromSize(
                  size: _buttonSize,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () => _handleTrackButtonPress(context),
                    child: Text(
                      'TRACK',
                      style: _titleStyle.copyWith(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSynopsisCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: _contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Synopsis', style: _titleStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              anime.synopsis ?? 'No synopsis available',
              style: _synopsisStyle,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
