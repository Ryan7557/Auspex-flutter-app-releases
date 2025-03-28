import 'package:auspex/ViewModel/anime_viewmodel.dart';
import 'package:auspex/Widgets/anime_card.dart';
import 'package:auspex/Widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class TrackedAnimePage extends StatefulWidget {
  const TrackedAnimePage({super.key});

  @override
  State<TrackedAnimePage> createState() => _TrackedAnimePageState();
}

class _TrackedAnimePageState extends State<TrackedAnimePage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;

  static final _emptyStateStyle = GoogleFonts.vt323(
    fontSize: 35,
    fontWeight: FontWeight.bold,
  );

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 0.7,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fetch tracked anime when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<AnimeViewModel>();
      viewModel.fetchTrackedAnime().then((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      body: Consumer<AnimeViewModel>(
        builder: (context, animeViewModel, _) {
          if (animeViewModel.isLoading) {
            return Center(
              child: LoadingAnimationWidget.beat(
                color: Colors.deepPurple,
                size: 60,
              ),
            );
          }

          if (animeViewModel.trackedAnime.isEmpty) {
            return Center(
              child: Text('No Tracked Anime Yet!', style: _emptyStateStyle),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SliverGrid(
                  gridDelegate: _gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final anime = animeViewModel.trackedAnime[index];
                      return TrackedAnimeCard(
                        key: ValueKey(anime.malId),
                        anime: anime,
                        animation: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index / animeViewModel.trackedAnime.length) * 0.5,
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );
                    },
                    childCount: animeViewModel.trackedAnime.length,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
