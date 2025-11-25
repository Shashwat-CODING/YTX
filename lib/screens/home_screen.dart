import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ytx/providers/navigation_provider.dart';
import 'package:ytx/providers/explore_provider.dart';
import 'package:ytx/screens/search_screen.dart';
import 'package:ytx/widgets/result_tile.dart';
import 'package:ytx/screens/library_screen.dart';
import 'package:ytx/screens/subscribed_channels_screen.dart';
import 'package:ytx/widgets/horizontal_result_card.dart';
import 'package:ytx/models/ytify_result.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildExploreTab(context, ref),
          const SearchScreen(),
          const LibraryScreen(),
          const SubscribedChannelsScreen(),
          // Placeholder for Settings (index 4)
          const SizedBox.shrink(), 
          const SizedBox.shrink(), // Placeholder for About (index 5)
        ],
      ),
    );
  }

  Widget _buildExploreTab(BuildContext context, WidgetRef ref) {
    final newestSongsAsync = ref.watch(newestSongsProvider);
    final newestVideosAsync = ref.watch(newestVideosProvider);
    final trendingPlaylistsAsync = ref.watch(trendingPlaylistsProvider);
    
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Explore',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.cast, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          
          // Newest Songs Section
          SliverToBoxAdapter(
            child: _buildSongSection(
              context, 
              title: 'Songs', 
              contentAsync: newestSongsAsync,
            ),
          ),

          // Newest Videos Section
          SliverToBoxAdapter(
            child: _buildSection(
              context, 
              title: 'Newest Videos', 
              contentAsync: newestVideosAsync,
              isVideo: true,
            ),
          ),

          // Trending Playlists Section
          SliverToBoxAdapter(
            child: _buildSection(
              context, 
              title: 'Trending Playlists', 
              contentAsync: trendingPlaylistsAsync,
              isVideo: false, // Playlists can be square
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildSongSection(
    BuildContext context, {
    required String title,
    required AsyncValue<List<YtifyResult>> contentAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280, // Height for 4 items vertically (approx 60-70 each)
          child: contentAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return const Center(child: Text('No content', style: TextStyle(color: Colors.grey)));
              }
              
              // Chunk results into groups of 4
              final chunks = <List<YtifyResult>>[];
              for (var i = 0; i < results.length; i += 4) {
                chunks.add(results.sublist(i, i + 4 > results.length ? results.length : i + 4));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: chunks.length,
                itemBuilder: (context, index) {
                  final chunk = chunks[index];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: chunk.map((result) => Expanded(
                        child: ResultTile(
                          result: result,
                          compact: true, // We need to add this property to ResultTile or just use it as is if it fits
                        ),
                      )).toList(),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required AsyncValue<List<YtifyResult>> contentAsync,
    required bool isVideo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: isVideo ? 240 : 260, // Increased height for playlists to prevent overflow
          child: contentAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return const Center(child: Text('No content', style: TextStyle(color: Colors.grey)));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return HorizontalResultCard(
                    result: results[index],
                    isVideo: isVideo,
                    width: isVideo ? 240 : 160, // Wider for videos
                  );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: isVideo ? 240 : 160,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
