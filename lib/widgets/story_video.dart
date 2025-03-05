import 'dart:async';

import 'package:flutter/material.dart';
import 'package:story_view/controller/story_controller.dart';

class StoryVideo extends StatefulWidget {
  const StoryVideo({
    super.key,
    required this.storyController,
    required this.playerAspectRatio,
    required this.playerCRInit,
    required this.onPause,
    required this.onPlay,
    required this.videoWidget,
    this.loadingWidget,
    this.errorWidget,
    this.errorDescription,
  });

  final StoryController storyController;

  final Future<void> Function() playerCRInit;
  final void Function() onPause;
  final void Function() onPlay;
  final double playerAspectRatio;
  final Widget? videoWidget;

  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? errorDescription;

  @override
  State<StatefulWidget> createState() => StoryVideoState();
}

class StoryVideoState extends State<StoryVideo> {
  StreamSubscription? _streamSubscription;
  bool _videoPRisInitialized = false;

  @override
  void initState() {
    super.initState();

    widget.storyController.pause();

    widget.playerCRInit.call().then((_) {
      if (mounted) {
        setState(() {
          _videoPRisInitialized = true;
        });
      }
    });

    _streamSubscription =
        widget.storyController.playbackNotifier.listen((playbackState) {
      if (playbackState == PlaybackState.pause) {
        widget.onPause();
      } else if (playbackState == PlaybackState.play) {
        widget.onPlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: Center(
          child: widget.errorDescription != null
              ? _videoPRisInitialized
                  ? AspectRatio(
                      aspectRatio: widget.playerAspectRatio,
                      child: widget.videoWidget,
                    )
                  : widget.loadingWidget ?? const CircularProgressIndicator()
              : widget.errorWidget ?? const Text('Video upload error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
