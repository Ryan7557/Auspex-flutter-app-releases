import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ViewModel/anime_viewmodel.dart';
import 'carousel_images.dart';

class CarouselWithSearch extends StatefulWidget {
  const CarouselWithSearch({super.key});

  @override
  State<CarouselWithSearch> createState() => _CarouselWithSearchState();
}

class _CarouselWithSearchState extends State<CarouselWithSearch> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> carouselItems = const [
    CarouselImages(
      imageUrl: 'https://4kwallpapers.com/images/walls/thumbs_3t/21091.png',
    ),
    CarouselImages(imageUrl: 'https://wallpaperaccess.com/full/4131922.jpg'),
    CarouselImages(
      imageUrl: 'https://4kwallpapers.com/images/walls/thumbs_3t/19704.png',
    ),
    CarouselImages(
      imageUrl: 'https://4kwallpapers.com/images/walls/thumbs_3t/16205.png',
    ),
    CarouselImages(
      imageUrl: 'https://picfiles.alphacoders.com/652/thumb-800-652364.webp',
    ),
  ];

  @override
  void dispose() {
    // TODO: implement dispose
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: CarouselSlider(
            items: carouselItems,
            carouselController: _carouselController,
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 8),
              enlargeCenterPage: true,
              viewportFraction: 1.0,
            ),
          ),
        ),
        Positioned(
          bottom: 62,
          child: Consumer<AnimeViewModel>(
            builder: (context, animeViewModel, _) {
              return AnimSearchBar(
                width: MediaQuery.of(context).size.width * 0.8,
                helpText: 'Search For Anime',
                // style: const TextStyle(color: Colors.black),
                boxShadow: true,
                textController: _searchController,
                suffixIcon: const Icon(Icons.search),
                onSuffixTap: () {
                  if (_searchController.text.isNotEmpty) {
                    animeViewModel.searchAnime(_searchController.text);
                  }
                },
                onSubmitted: animeViewModel.searchAnime,
              );
            },
          ),
        ),
        Positioned(
          bottom: 150,
          child: Text(
            'Search For Anime',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: GoogleFonts.vt323().fontFamily,
              fontSize: 30,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
