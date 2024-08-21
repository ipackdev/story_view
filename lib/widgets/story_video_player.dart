import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../story_view.dart';

class StoryVideoPlayer extends StatefulWidget {
  StoryVideoPlayer({
    Key? key,
    required this.videoLoader,
    required this.storyCR,
    this.whenVideoPlayerReady,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key ?? UniqueKey());

  final StoryController storyCR;
  final Function(VideoPlayerController)? whenVideoPlayerReady;
  final VideoLoader videoLoader;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  @override
  State<StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  late VideoPlayerController _playerCR;
  late StreamSubscription<PlaybackState> _streamPlayback;

  @override
  void initState() {
    super.initState();

    widget.storyCR.pause();
    widget.videoLoader.loadVideo(_onCompleteLoadVideo);
  }

  void _onCompleteLoadVideo() {
    if (widget.videoLoader.state == LoadState.success) {
      _initVideoPlayer();
      _streamPlayback = widget.storyCR.playbackNotifier.listen(
        (playbackState) => playbackState == PlaybackState.pause
            ? _playerCR.pause()
            : _playerCR.play(),
      );
    } else {
      setState(() {});
    }
  }

  void _initVideoPlayer() {
    _playerCR = VideoPlayerController.file(widget.videoLoader.videoFile!);
    _playerCR.initialize().then((_) {
      widget.storyCR.play();
      setState(() {});
      widget.whenVideoPlayerReady?.call(_playerCR);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: Center(
          child: widget.videoLoader.state == LoadState.success &&
                  _playerCR.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _playerCR.value.aspectRatio,
                  child: VideoPlayer(_playerCR),
                )
              : widget.videoLoader.state == LoadState.loading
                  ? widget.loadingWidget ??
                      const SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      )
                  : widget.errorWidget ??
                      const Text(
                        "Media failed to load",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playerCR.dispose();
    _streamPlayback.cancel();
    // todo(21.08.2024): [Cannot guard a call to State.setState() from within State.dispose(). · Issue #25536 · flutter/flutter](https://github.com/flutter/flutter/issues/25536)

    super.dispose();
  }
}
