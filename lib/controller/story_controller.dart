import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:rxdart/rxdart.dart';

enum PlaybackState { pause, play, next, previous, idle, finish }

/// Controller to sync playback between animated child (story) views. This
/// helps make sure when stories are paused, the animation (gifs/slides) are
/// also paused.
/// Another reason for using the controller is to place the stories on `paused`
/// state when a media is loading.
class StoryController extends ValueNotifier<void> {
  StoryController() : super(null) {
    playbackNR.add(PlaybackState.idle);
  }

  final currentIndexNR = ValueNotifier<int>(0);
  int get currentIndex => currentIndexNR.value;

  /// Stream that broadcasts the playback state of the stories.
  final playbackNR = BehaviorSubject<PlaybackState>();

  /// Notify listeners with a [PlaybackState.pause] state
  void pause() {
    if (isDisposed) return;

    playbackNR.add(PlaybackState.pause);
  }

  /// Notify listeners with a [PlaybackState.play] state
  void play() {
    if (isDisposed) return;

    playbackNR.add(PlaybackState.play);
  }

  void next() {
    if (isDisposed) return;

    playbackNR.add(PlaybackState.next);
  }

  void previous() {
    if (isDisposed) return;

    playbackNR.add(PlaybackState.previous);
  }

  void finish() {
    if (isDisposed) return;

    playbackNR.add(PlaybackState.finish);
  }

  void idle() {
    if (isDisposed) return;

    playbackNR.add(PlaybackState.idle);
  }

  PlaybackState get lastValue => playbackNR.value;

  bool get isDisposed => playbackNR.isClosed;

  /// Remember to call dispose when the story screen is disposed to close
  /// the notifier stream.
  @override
  void dispose() {
    playbackNR.close();
    currentIndexNR.dispose();
    super.dispose();
  }
}
