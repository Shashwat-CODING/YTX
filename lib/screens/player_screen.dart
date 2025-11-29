import 'dart:ui';
import 'package:marquee/marquee.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:ytx/providers/player_provider.dart';
import 'package:ytx/services/storage_service.dart';
import 'package:ytx/models/ytify_result.dart';
import 'package:ytx/services/download_service.dart';
import 'package:ytx/providers/download_provider.dart';
import 'package:ytx/widgets/app_alert_dialog.dart';
import 'package:ytx/widgets/glass_snackbar.dart';
import 'package:ytx/widgets/playlist_selection_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:ytx/screens/artist_screen.dart';

class ExpandedPlayer extends ConsumerStatefulWidget {
  const ExpandedPlayer({super.key});

  @override
  ConsumerState<ExpandedPlayer> createState() => _ExpandedPlayerState();
}

class _ExpandedPlayerState extends ConsumerState<ExpandedPlayer> {
  bool _showQueue = false;

  @override
  Widget build(BuildContext context) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    // Calculate margins to keep player between header and nav bar
    // final double topMargin = MediaQuery.of(context).padding.top + 16.0;
    // final double bottomMargin = 100.0 + MediaQuery.of(context).padding.bottom;
    // const double sideMargin = 16.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: mediaItemAsync.when(
        data: (mediaItem) {
          if (mediaItem == null) return const SizedBox.shrink();

          final resultType = mediaItem.extras?['resultType'] ?? 'video';
          final isSong = resultType == 'song';
          String artworkUrl = mediaItem.artUri.toString();
          
          // Replace low quality thumbnail with higher quality if pattern matches
          if (artworkUrl.contains('=w120-h120')) {
            artworkUrl = artworkUrl.replaceAll('=w120-h120', '=w300-h300');
          } else if (artworkUrl.contains('=w60-h60')) {
             artworkUrl = artworkUrl.replaceAll('=w60-h60', '=w300-h300');
          }

          return Stack(
            children: [
              // Transparent Background (Click to close)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                ),
              ),

              // Floating Card
              Dismissible(
                key: const Key('player_dismiss'),
                direction: DismissDirection.down,
                onDismissed: (_) => Navigator.of(context).pop(),
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  child: Stack(
                    children: [
                        // Background Image with Blur
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: artworkUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(color: Colors.black),
                          ),
                        ),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.8), // Darker overlay
                            ),
                          ),
                        ),


                        // Content
                        Column(
                          children: [
                            // Header / Drag Handle
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.white, size: 24),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    const Spacer(),
                                    // Drag Handle Indicator (Optional, but good for UX)
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white, size: 20),
                                      onSelected: (value) => _handleMenuAction(context, ref, value, mediaItem, isSong),
                                      itemBuilder: (BuildContext context) {
                                        final storage = ref.read(storageServiceProvider);
                                        // Note: PopupMenu doesn't rebuild on state change automatically unless we force it, 
                                        // but for these simple toggles it's okay if it reflects state at open time.
                                        final isFav = storage.isFavorite(mediaItem.id);
                                        final isDownloaded = storage.isDownloaded(mediaItem.id);
                                        
                                        return [
                                          const PopupMenuItem<String>(
                                            value: 'playlist',
                                            child: Row(
                                              children: [
                                                FaIcon(FontAwesomeIcons.plus, size: 16),
                                                SizedBox(width: 12),
                                                Text('Add to Playlist'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'favorite',
                                            child: Row(
                                              children: [
                                                FaIcon(isFav ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart, 
                                                  color: isFav ? Colors.red : null, size: 16),
                                                const SizedBox(width: 12),
                                                Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'download',
                                            child: Row(
                                              children: [
                                                FaIcon(isDownloaded ? FontAwesomeIcons.check : FontAwesomeIcons.download, size: 16),
                                                const SizedBox(width: 12),
                                                Text(isDownloaded ? 'Remove Download' : 'Download'),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Main Player Content
                            if (!_showQueue)
                              Expanded(
                                child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Artwork
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: isSong ? 32.0 : 10.0),
                                                child: AspectRatio(
                                                  aspectRatio: isSong ? 1.0 : 16 / 9,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.4),
                                                          blurRadius: 20,
                                                          offset: const Offset(0, 10),
                                                        ),
                                                      ],
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: artworkUrl,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context, url, error) => Container(
                                                        color: Colors.grey[900],
                                                        child: const FaIcon(FontAwesomeIcons.music,
                                                            color: Colors.white, size: 64),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 40), // Shifted up by reducing top space elsewhere or just adjusting layout

                                              // Title and Artist
                                              Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(horizontal: isSong ? 32.0 : 10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        final textStyle = const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        );
                                                        final textSpan = TextSpan(
                                                          text: mediaItem.title,
                                                          style: textStyle,
                                                        );
                                                        final textPainter = TextPainter(
                                                          text: textSpan,
                                                          textDirection: TextDirection.ltr,
                                                          maxLines: 1,
                                                        );
                                                        textPainter.layout(maxWidth: double.infinity);

                                                        if (textPainter.width > constraints.maxWidth) {
                                                          return SizedBox(
                                                            height: 30,
                                                            child: Marquee(
                                                              text: mediaItem.title,
                                                              style: textStyle,
                                                              scrollAxis: Axis.horizontal,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              blankSpace: 50.0,
                                                              velocity: 30.0,
                                                              pauseAfterRound: const Duration(seconds: 3),
                                                              startPadding: 0.0,
                                                              accelerationDuration: const Duration(seconds: 1),
                                                              accelerationCurve: Curves.linear,
                                                              decelerationDuration: const Duration(milliseconds: 500),
                                                              decelerationCurve: Curves.easeOut,
                                                            ),
                                                          );
                                                        } else {
                                                          return Text(
                                                            mediaItem.title,
                                                            style: textStyle,
                                                            textAlign: TextAlign.left,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      mediaItem.artist ?? '',
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.7),
                                                        fontSize: 14,
                                                      ),
                                                      textAlign: TextAlign.left,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),

                                              // Seek Bar
                                              StreamBuilder<Duration>(
                                                stream: audioHandler.player.positionStream,
                                                builder: (context, snapshot) {
                                                  final position = snapshot.data ?? Duration.zero;
                                                  final duration = audioHandler.player.duration ?? Duration.zero;

                                                  return Column(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                        child: SliderTheme(
                                                          data: SliderTheme.of(context).copyWith(
                                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                            trackHeight: 4,
                                                            activeTrackColor: Theme.of(context).colorScheme.primary,
                                                            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                                                            thumbColor: Theme.of(context).colorScheme.primary,
                                                            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                                          ),
                                                          child: Slider(
                                                            value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                                                            min: 0,
                                                            max: duration.inSeconds.toDouble(),
                                                            onChanged: (value) {
                                                              audioHandler.seek(Duration(seconds: value.toInt()));
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 32),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              _formatDuration(position),
                                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                                            ),
                                                            Text(
                                                              _formatDuration(duration),
                                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 16),

                                              // Controls
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [



                                                  IconButton(
                                                    icon: const FaIcon(FontAwesomeIcons.backwardStep, color: Colors.white, size: 28),
                                                    onPressed: () => audioHandler.skipToPrevious(),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  isPlayingAsync.when(
                                                    data: (isPlaying) => Container(
                                                      width: 64, // Reduced size
                                                      height: 64, // Reduced size
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.2),
                                                            blurRadius: 10,
                                                            offset: const Offset(0, 4),
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton(
                                                        icon: FaIcon(
                                                          isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                                          color: Colors.black,
                                                          size: 28, // Reduced size
                                                        ),
                                                        onPressed: () {
                                                          if (isPlaying) {
                                                            audioHandler.pause();
                                                          } else {
                                                            audioHandler.resume();
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    loading: () => const SizedBox(
                                                        width: 64,
                                                        height: 64,
                                                        child: CircularProgressIndicator(color: Colors.white)
                                                    ),
                                                    error: (_, __) => const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.red),
                                                  ),
                                                  IconButton(
                                                    icon: const FaIcon(FontAwesomeIcons.forwardStep, color: Colors.white, size: 28),
                                                    onPressed: () => audioHandler.skipToNext(),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),

                                                ],
                                              ),
                                            ),
                                              const SizedBox(height: 32),

                                              // Bottom Action Bar (Fav, Up Next, Download)
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                child: Center(
                                                  child: GestureDetector(
                                                    onTap: () => setState(() => _showQueue = true),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(30),
                                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'UP NEXT',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                              letterSpacing: 1,
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                            else
                              // Queue View
                              Expanded(
                                      child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.white),
                                                onPressed: () => setState(() => _showQueue = false),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('Up Next', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              audioHandler.clearQueue();
                                              setState(() => _showQueue = false);
                                            },
                                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: StreamBuilder<SequenceState?>(
                                        stream: audioHandler.player.sequenceStateStream,
                                        builder: (context, snapshot) {
                                          final state = snapshot.data;
                                          final sequence = state?.sequence ?? [];
                                          
                                          if (sequence.isEmpty) {
                                            return const Center(child: Text('Queue is empty', style: TextStyle(color: Colors.grey)));
                                          }

                                          return ReorderableListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: sequence.length,
                                            onReorder: (oldIndex, newIndex) {
                                              audioHandler.reorderQueue(oldIndex, newIndex);
                                            },
                                            proxyDecorator: (child, index, animation) {
                                              return Material(
                                                color: Colors.transparent,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2E2E2E),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            itemBuilder: (context, index) {
                                              final item = sequence[index];
                                              final metadata = item.tag as MediaItem;
                                              final isPlaying = index == state?.currentIndex;
                                              
                                              // Calculate aspect ratio
                                              final resultType = metadata.extras?['resultType'] ?? 'video';
                                              final isVideo = resultType == 'video';
                                              final aspectRatio = isVideo ? 16 / 9 : 1.0;
                                            
                                              return Dismissible(
                                                key: ValueKey(item),
                                                direction: DismissDirection.endToStart,
                                                background: Container(
                                                  color: Colors.red,
                                                  alignment: Alignment.centerRight,
                                                  padding: const EdgeInsets.only(right: 20),
                                                  child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
                                                ),
                                                onDismissed: (direction) {
                                                  audioHandler.removeQueueItem(index);
                                                },
                                                child: Padding(
                                                  padding: index == sequence.length - 1 
                                                    ? EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16) 
                                                    : EdgeInsets.zero,
                                                  child: ListTile(
                                                    dense: true,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                    leading: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isPlaying)
                                                          const Padding(
                                                            padding: EdgeInsets.only(right: 8.0),
                                                            child: FaIcon(FontAwesomeIcons.chartSimple, color: Colors.red, size: 20),
                                                          )
                                                        else
                                                          const SizedBox(width: 28), // Placeholder for alignment
                                                        
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(4),
                                                          child: SizedBox(
                                                            height: 48,
                                                            width: 48 * aspectRatio,
                                                            child: CachedNetworkImage(
                                                              imageUrl: metadata.artUri.toString(),
                                                              fit: BoxFit.cover,
                                                              errorWidget: (context, url, error) => Container(
                                                                color: Colors.grey[800],
                                                                child: const FaIcon(FontAwesomeIcons.music, color: Colors.white),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                      title: Text(
                                                        metadata.title,
                                                        style: TextStyle(
                                                          color: isPlaying ? Colors.red : Colors.white,
                                                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      subtitle: Text(
                                                        metadata.artist ?? '',
                                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      trailing: const FaIcon(FontAwesomeIcons.gripLines, color: Colors.grey),
                                                      onTap: () {
                                                        audioHandler.seek(Duration.zero, index: index);
                                                      },
                                                    ),
                                                  ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading player', style: TextStyle(color: Colors.white))),
      ),
    );
  }



  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value, MediaItem mediaItem, bool isSong) async {
    final storage = ref.read(storageServiceProvider);
    final result = YtifyResult(
      videoId: mediaItem.id,
      title: mediaItem.title,
      thumbnails: [YtifyThumbnail(url: mediaItem.artUri.toString(), width: 0, height: 0)],
      artists: [YtifyArtist(name: mediaItem.artist ?? '', id: '')], 
      resultType: isSong ? 'song' : 'video',
      isExplicit: false,
    );

    switch (value) {
      case 'playlist':
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => PlaylistSelectionDialog(song: result),
        );
        break;
      case 'favorite':
        storage.toggleFavorite(result);
        break;
      case 'download':
        final isDownloaded = storage.isDownloaded(mediaItem.id);
        final downloadService = DownloadService();
        if (isDownloaded) {
          await downloadService.deleteDownload(mediaItem.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removed from downloads')),
            );
          }
        } else {
          // Show downloading alert
          bool isDialogVisible = true;
          showAppAlertDialog(
            context: context,
            title: 'Downloading',
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please wait while the song is being downloaded...'),
                SizedBox(height: 16),
                CupertinoActivityIndicator(),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hide'),
              ),
            ],
          ).then((_) => isDialogVisible = false);

          final success = await ref.read(downloadProvider.notifier).startDownload(result);
          
          if (context.mounted) {
            if (isDialogVisible) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            if (success) {
              showGlassSnackBar(context, 'Download complete');
            } else {
              showGlassSnackBar(context, 'Download failed - Please try again');
            }
          }
        }
        break;
    }
  }
}
