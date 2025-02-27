import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:story_view/controller/story_controller.dart';

/// Indicates where the progress indicators should be placed.
enum ProgressPosition { top, bottom, none }

/// This is used to specify the height of the progress indicator. Inline stories
/// should use [small]
enum IndicatorHeight { small, medium, large }

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous page.
class StoryView<T> extends StatefulWidget {
  /// The pages to displayed.
  final List<T> storyItems;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback? onComplete;

  /// Callback for when a story and it index is currently being shown.
  final void Function(T storyItem, int index)? onStoryShow;

  /// Callback for when a show story widget.
  final Widget Function(BuildContext context, T storyItem, int index) builder;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  /// Controls the playback of the stories
  final StoryController controller;

  /// Indicator Color
  final Color? indicatorColor;

  /// Indicator Foreground Color
  final Color? indicatorForegroundColor;

  /// Determine the height of the indicator
  final IndicatorHeight indicatorHeight;

  /// Use this if you want to give outer padding to the indicator
  final EdgeInsetsGeometry indicatorOuterPadding;

  /// A widget that appears on top of all elements. Maybe [Positioned]
  final Widget? stackChild;

  const StoryView({
    super.key,
    required this.storyItems,
    required this.controller,
    this.onComplete,
    this.stackChild,
    this.onStoryShow,
    required this.builder,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorOuterPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  });

  @override
  State<StatefulWidget> createState() => StoryViewState();
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController? _animationCR;
  Animation<double>? _currentAnimation;
  Timer? _nextDebouncer;

  StreamSubscription<PlaybackState>? _playbackSub;

  int currentStoryIndex = 0;

  int get _currentStoryIndex => currentStoryIndex;

  set _currentStoryIndex(int value) {
    print('now index: $value');
    currentStoryIndex = value;
  }

  @override
  void initState() {
    super.initState();

    _playbackSub = widget.controller.playbackNotifier.listen(_listenPlayback);

    _play();
  }

  void _listenPlayback(PlaybackState playbackStatus) {
    print(playbackStatus);
    switch (playbackStatus) {
      case PlaybackState.play:
        _removeNextHold();
        _animationCR?.forward();

      case PlaybackState.pause:
        _holdNext(); // then pause animation
        _animationCR?.stop(canceled: false);

      case PlaybackState.next:
        _removeNextHold();
        _goForward();

      case PlaybackState.previous:
        _removeNextHold();
        _goBack();
    }
  }

  @override
  void dispose() {
    print('dispose');
    _clearDebouncer();

    _animationCR?.dispose();
    _playbackSub?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _play() {
    _animationCR?.dispose();

    // get the next playing page
    final storyItem = widget.storyItems[_currentStoryIndex];
    widget.onStoryShow?.call(storyItem, _currentStoryIndex);
    _animationCR =
        AnimationController(duration: storyItem.duration, vsync: this);

    _animationCR!.addStatusListener((status) {
      print(status);
      if (status == AnimationStatus.completed) {
        if (_currentStoryIndex + 1 == widget.storyItems.length) {
          _onComplete();
        } else {
          _currentStoryIndex += 1;
          _beginPlay();
        }
      }
    });

    _currentAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationCR!);

    widget.controller.play();
  }

  void _beginPlay() {
    _play();
    setState(() {});
  }

  void _onComplete() {
    widget.onComplete?.call();
    if (widget.onComplete != null) widget.controller.pause();

    if (widget.repeat) {
      _currentStoryIndex = 0;
      _beginPlay();
    }
  }

  void _goBack() {
    _currentStoryIndex -= 1;
    _beginPlay();
  }

  void _goForward() {
    _currentStoryIndex += 1;
    if (_currentStoryIndex + 1 != widget.storyItems.length) {
      _animationCR!.stop();
      _beginPlay();
    } else {
      // this is the last page, progress animation should skip to end
      _animationCR!.animateTo(1.0, duration: const Duration(milliseconds: 10));
    }
  }

  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _removeNextHold() => _clearDebouncer();

  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(const Duration(milliseconds: 500), () {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: <Widget>[
          widget.builder(
            context,
            widget.storyItems[_currentStoryIndex]!,
            _currentStoryIndex,
          ),
          Visibility(
            visible: widget.progressPosition != ProgressPosition.none,
            child: Align(
              alignment: widget.progressPosition == ProgressPosition.top
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: SafeArea(
                bottom: !widget.inline,
                child: Padding(
                  padding: widget.indicatorOuterPadding,
                  child: PageBar(
                    key: UniqueKey(),
                    currentIndex: _currentStoryIndex,
                    itemCount: widget.storyItems.length,
                    animation: _currentAnimation,
                    indicatorHeight: widget.indicatorHeight,
                    indicatorColor: widget.indicatorColor,
                    indicatorForegroundColor: widget.indicatorForegroundColor,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width - 140,
              child: GestureDetector(
                onTapDown: (_) {
                  widget.controller.pause();
                },
                onTapCancel: () {
                  widget.controller.play();
                },
                onTapUp: (_) {
                  // if debounce timed out (not active) then continue anim
                  if (_nextDebouncer?.isActive == false) {
                    widget.controller.play();
                  } else {
                    widget.controller.next();
                  }
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: () {
                  widget.controller.next();
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: () {
                  widget.controller.previous();
                },
              ),
            ),
          ),
          if (widget.stackChild != null) widget.stackChild!,
        ],
      ),
    );
  }
}

/// Capsule holding the duration and shown property of each story. Passed down
/// to the pages bar to render the page indicators.
class PageData {
  Duration duration;
  bool shown;

  PageData(this.duration, this.shown);
}

/// Horizontal bar displaying a row of [StoryProgressIndicator] based on the
/// [pages] provided.
class PageBar extends StatefulWidget {
  final int itemCount;
  final int currentIndex;
  final Animation<double>? animation;
  final IndicatorHeight indicatorHeight;
  final Color? indicatorColor;
  final Color? indicatorForegroundColor;

  const PageBar({
    required this.itemCount,
    required this.currentIndex,
    this.animation,
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorColor,
    this.indicatorForegroundColor,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => PageBarState();
}

class PageBarState extends State<PageBar> {
  double spacing = 4;

  @override
  void initState() {
    super.initState();

    int count = widget.itemCount;
    spacing = (count > 15) ? 2 : ((count > 10) ? 3 : 4);

    widget.animation!.addListener(() => setState(() {}));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < widget.itemCount; ++i)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                    widget.currentIndex + 1 == widget.itemCount ? 0 : spacing,
              ),
              child: StoryProgressIndicator(
                widget.currentIndex == i ? widget.animation!.value : 0,
                indicatorHeight: widget.indicatorHeight == IndicatorHeight.large
                    ? 5
                    : widget.indicatorHeight == IndicatorHeight.medium
                        ? 3
                        : 2,
                indicatorColor: widget.indicatorColor,
                indicatorForegroundColor: widget.indicatorForegroundColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom progress bar. Supposed to be lighter than the
/// original [ProgressIndicator], and rounded at the sides.
class StoryProgressIndicator extends StatelessWidget {
  /// From `0.0` to `1.0`, determines the progress of the indicator
  final double value;
  final double indicatorHeight;
  final Color? indicatorColor;
  final Color? indicatorForegroundColor;

  const StoryProgressIndicator(
    this.value, {
    super.key,
    this.indicatorHeight = 5,
    this.indicatorColor,
    this.indicatorForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        indicatorForegroundColor ?? Colors.white.withOpacity(0.8),
        value,
      ),
      painter: IndicatorOval(
        indicatorColor ?? Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  final Color color;
  final double widthFactor;

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * widthFactor, size.height),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Concept source: https://stackoverflow.com/a/9733420
class ContrastHelper {
  static double luminance(int? r, int? g, int? b) {
    final a = [r, g, b].map((it) {
      double value = it!.toDouble() / 255.0;
      return value <= 0.03928
          ? value / 12.92
          : pow((value + 0.055) / 1.055, 2.4);
    }).toList();

    return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
  }
}
