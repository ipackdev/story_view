## story_view fork

Carousel for photos, videos and any other widgets. Is a completely redesigned fork of the [story_view](https://pub.dev/packages/story_view)

## Example

```dart
  @override
Widget build(BuildContext context, WidgetRef ref) {
  // use flutter_hooks
  final storyCR = useListenable(StoryController());

  return StoryView(
    indicatorColor: Colors.red,
    indicatorForegroundColor: Colors.white,
    itemCount: 5,
    itemBuilder: (context, index, onReady) => MyStoryWidget(
      storyCR: storyCR,
      onReady: onReady,
    ),
    controller: storyCR,
    inline: true,
    repeat: true,
    progressPosition: ProgressPosition.bottom,
    autostart: false,
  );
}
```