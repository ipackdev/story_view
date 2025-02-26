import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../controller/story_controller.dart';
import '../utils.dart';

class VideoLoader {
  String url;

  File? videoFile;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (videoFile != null) {
      state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager()
        .getFileStream(url, headers: requestHeaders as Map<String, String>?);

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (videoFile == null) {
          state = LoadState.success;
          videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

class StoryVideo extends StatefulWidget {
  StoryVideo(
    this.videoLoader, {
    Key? key,
    required this.storyController,
    // playerController!.value.aspectRatio
    required this.playerAspectRatio,
    required this.playerCRInit,
    required this.onPause,
    required this.onPlay,
    required this.videoWidget,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key ?? UniqueKey());

  final StoryController storyController;

  final Future<void> Function() playerCRInit;
  final void Function() onPause;
  final void Function() onPlay;
  final double playerAspectRatio;
  final Widget? videoWidget;

  final VideoLoader videoLoader;

  final Widget? loadingWidget;
  final Widget? errorWidget;

  @override
  State<StatefulWidget> createState() => StoryVideoState();
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;
  bool videoPRisInitialized = false;

  @override
  void initState() {
    super.initState();

    widget.storyController.pause();

    widget.videoLoader.loadVideo(() {
      if (widget.videoLoader.state == LoadState.success) {
        widget.playerCRInit.call().then((_) {
          setState(() {
            videoPRisInitialized = true;
          });
          widget.storyController.play();
        });

        _streamSubscription =
            widget.storyController.playbackNotifier.listen((playbackState) {
          if (playbackState == PlaybackState.pause) {
            widget.onPause();
          } else {
            widget.onPlay();
          }
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: Builder(
        builder: (context) {
          if (widget.videoLoader.state == LoadState.success &&
              videoPRisInitialized) {
            return Center(
              child: AspectRatio(
                aspectRatio: widget.playerAspectRatio,
                child: widget.videoWidget,
              ),
            );
          }

          return Center(
            child: widget.videoLoader.state == LoadState.loading
                ? widget.loadingWidget ??
                    const SizedBox.square(
                      dimension: 70,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                : widget.errorWidget ??
                    const Text(
                      "Media failed to load",
                      style: TextStyle(color: Colors.white),
                    ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
