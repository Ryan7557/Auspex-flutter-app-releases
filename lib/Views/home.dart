import 'package:auspex/ViewModel/anime_viewmodel.dart';
import 'package:auspex/Views/settings_screen.dart';
import 'package:auspex/Views/tracked_anime.dart';
import 'package:auspex/Widgets/anime_card.dart';
import 'package:auspex/Widgets/carousel_with_search.dart';
import 'package:auspex/Widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  final GlobalKey<SliverAnimatedGridState> _gridKey =
      GlobalKey<SliverAnimatedGridState>();

  // Cache grid delegate
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 5.0,
    mainAxisSpacing: 5.0,
    childAspectRatio: 0.7,
  );

  // Cache styles
  static final _drawerTitleStyle = GoogleFonts.vt323(
    fontSize: 35,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static final _drawerItemStyle = GoogleFonts.vt323(
    fontSize: 40,
    color: Colors.white,
  );

  static final _errorStyle = GoogleFonts.vt323(
    fontSize: 30,
    color: Colors.red,
    fontWeight: FontWeight.w800,
  );

  // Cache drawer image decoration
  static final _drawerHeaderDecoration = BoxDecoration(
    image: DecorationImage(
      image: const NetworkImage(
        'https://images3.alphacoders.com/134/thumb-1920-1348435.png',
      ),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
        BlendMode.darken,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Optimize initial data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = Provider.of<AnimeViewModel>(context, listen: false);
      viewModel.fetchTopAnime().then((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    });
  }

  // Extract grid builder for better performance
  Widget _buildAnimeGrid(AnimeViewModel viewModel) {
    return SliverPadding(
      padding: const EdgeInsets.all(5.0),
      sliver: SliverAnimatedGrid(
        key: _gridKey,
        gridDelegate: _gridDelegate,
        initialItemCount: viewModel.animelist.length,
        itemBuilder: (context, index, animation) {
          final anime = viewModel.animelist[index];
          return RepaintBoundary(
            child: AnimeCard(
              key: ValueKey(anime.malId),
              anime: anime,
              animation: animation,
            ),
          );
        },
      ),
    );
  }

  // Extract loading widget
  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: 55),
        child: Center(
          child: LoadingAnimationWidget.beat(
            color: Colors.deepPurple,
            size: 60,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Move test button to proper sliver widget
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // child: ElevatedButton(
              //   onPressed: () => NotificationService.testNotification(),
              //   child: const Text('Test Notifications'),
              // ),
            ),
          ),
          // Optimize carousel loading
          SliverToBoxAdapter(
            child: RepaintBoundary(child: CarouselWithSearch()),
          ),
          Consumer<AnimeViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.error != null) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: ${viewModel.error}',
                      style: _errorStyle,
                    ),
                  ),
                );
              }

              if (viewModel.isLoading) return _buildLoadingState();

              if (viewModel.animelist.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 55),
                    child: Center(
                      child: Text('No Anime Found', style: _errorStyle),
                    ),
                  ),
                );
              }

              return _buildAnimeGrid(viewModel);
            },
          ),
        ],
      ),
      drawer: RepaintBoundary(child: _buildDrawer(context)),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      elevation: 16.0,
      width: 280,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: _drawerHeaderDecoration,
            child: Container(
              height: 500,
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: AlignmentDirectional.center,
              child: Text('AUSPEX', style: _drawerTitleStyle),
            ),
          ),
          const SizedBox(height: 50),
          _buildDrawerItem(
            title: 'ANIME',
            icon: Icons.tv,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 5),
          _buildDrawerItem(
            title: 'SETTINGS',
            icon: Icons.settings,
            onTap: () {
              // Implement Manga Route
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 5),
          _buildDrawerItem(
            title: 'FAVOURITES',
            icon: Icons.favorite,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackedAnimePage(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: _drawerItemStyle),
      leading: Icon(icon, color: Colors.white),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
