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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: mediaItemAsync.when(
        data: (mediaItem) {
          if (mediaItem == null) return const SizedBox.shrink();
          return _buildPlayerContent(mediaItem);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (_, __) => const Center(child: Text('Error loading player', style: TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildPlayerContent(MediaItem mediaItem) {
    String artworkUrl = mediaItem.artUri.toString();
    if (artworkUrl.contains('=w120-h120')) {
      artworkUrl = artworkUrl.replaceAll('=w120-h120', '=w300-h300');
    } else if (artworkUrl.contains('=w60-h60')) {
      artworkUrl = artworkUrl.replaceAll('=w60-h60', '=w300-h300');
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.transparent),
        ),
        Dismissible(
          key: const Key('player_dismiss'),
          direction: DismissDirection.down,
          onDismissed: (_) => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                _buildBlurredBackground(artworkUrl),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(mediaItem),
                      if (!_showQueue)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 1),
                              _buildArtwork(artworkUrl, mediaItem),
                              const SizedBox(height: 40),
                              _buildTrackInfo(mediaItem),
                              const SizedBox(height: 32),
                              _buildProgressBar(),
                              const SizedBox(height: 24),
                              _buildControls(),
                              const Spacer(flex: 2),
                              _buildQueueButton(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        )
                      else
                        _buildQueueList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurredBackground(String artworkUrl) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: artworkUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(color: Colors.black),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MediaItem mediaItem) {
    final resultType = mediaItem.extras?['resultType'] ?? 'video';
    final isSong = resultType == 'song';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white, size: 20),
            onSelected: (value) => _handleMenuAction(context, ref, value, mediaItem, isSong),
            itemBuilder: (BuildContext context) => _buildMenuItems(ref, mediaItem),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(String artworkUrl, MediaItem mediaItem) {
    final resultType = mediaItem.extras?['resultType'] ?? 'video';
    final isSong = resultType == 'song';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: AspectRatio(
        aspectRatio: isSong ? 1.0 : 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: CachedNetworkImage(
              imageUrl: artworkUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[900],
                child: const FaIcon(FontAwesomeIcons.music, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(MediaItem mediaItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Center(
              child: Text(
                mediaItem.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mediaItem.artist ?? '',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final audioHandler = ref.watch(audioHandlerProvider);
    return StreamBuilder<Duration>(
      stream: audioHandler.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audioHandler.player.duration ?? Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.1),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()).toDouble(),
                min: 0.0,
                max: duration.inSeconds.toDouble(),
                onChanged: (value) {
                  audioHandler.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 28,
          icon: const FaIcon(FontAwesomeIcons.backwardStep, color: Colors.white),
          onPressed: () => audioHandler.skipToPrevious(),
        ),
        const SizedBox(width: 40),
        isPlayingAsync.when(
          data: (isPlaying) => Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: FaIcon(
                isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                color: Colors.black,
                size: 28,
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
            width: 72,
            height: 72,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
          error: (_, __) => const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.red, size: 32),
        ),
        const SizedBox(width: 40),
        IconButton(
          iconSize: 28,
          icon: const FaIcon(FontAwesomeIcons.forwardStep, color: Colors.white),
          onPressed: () => audioHandler.skipToNext(),
        ),
      ],
    );
  }

  Widget _buildQueueButton() {
    return GestureDetector(
      onTap: () => setState(() => _showQueue = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UP NEXT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 6),
            FaIcon(FontAwesomeIcons.chevronUp, color: Colors.white, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    final audioHandler = ref.watch(audioHandlerProvider);
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.white, size: 20),
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
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPlaying)
                              const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: FaIcon(FontAwesomeIcons.chartSimple, color: Colors.red, size: 16),
                              ),
                            
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 42,
                                width: 42 * aspectRatio,
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
                        trailing: const FaIcon(FontAwesomeIcons.gripLines, color: Colors.grey, size: 16),
                        onTap: () {
                          audioHandler.seek(Duration.zero, index: index);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(WidgetRef ref, MediaItem mediaItem) {
    final storage = ref.read(storageServiceProvider);
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
