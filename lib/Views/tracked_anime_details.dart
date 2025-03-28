import 'package:auspex/Models/anime_model.dart';
import 'package:auspex/ViewModel/anime_viewmodel.dart';
import 'package:auspex/Widgets/image_section.dart';
import 'package:auspex/Widgets/title_section.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TrackedAnimeDetailsPage extends StatelessWidget {
  const TrackedAnimeDetailsPage({super.key, required this.anime});
  final AnimeModel anime;

  // Memoize styles and dimensions
  static const _imageSize = Size(200, 300);
  static const _buttonSize = Size(200, 45);
  static const _contentPadding = EdgeInsets.all(16.0);

  static final _titleStyle = GoogleFonts.vt323(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static final _synopsisStyle = GoogleFonts.vt323(
    fontSize: 25,
    height: 1.5,
    color: Colors.black,
  );

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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(
                                'Remove from Tracking',
                                style: GoogleFonts.vt323(
                                  fontSize: 30,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to remove ${anime.title} from your tracking list?',
                                style: _synopsisStyle,
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.vt323(
                                      color: Colors.black,
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Remove',
                                    style: GoogleFonts.vt323(
                                      color: Colors.red,
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (shouldDelete == true && context.mounted) {
                        try {
                          final viewModel = context.read<AnimeViewModel>();
                          await viewModel.removeTrackedAnime(anime);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${anime.title} removed from tracking list',
                                  style: GoogleFonts.vt323(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                width: 350,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to remove ${anime.title} from tracking list',
                                  style: GoogleFonts.vt323(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                width: 350,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      'REMOVE',
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
