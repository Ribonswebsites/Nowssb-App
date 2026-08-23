# NowssB time-aware banner video map

The four supplied 15-second landscape videos are 16:9-compatible background assets with no text or faces. They are best assigned as follows:

| File | Slot | Visual treatment |
|---|---|---|
| `grok_video_2026-08-23-21-41-44.mp4` | Morning | Earth sunrise, bright gold-white rim light, blue/green planet, dark space |
| `grok_video_2026-08-23-21-42-49.mp4` | Afternoon | Bright daylight Earth, blue/green surface, clear high-key atmosphere |
| `grok_video_2026-08-23-21-41-56.mp4` | Evening | Warm orange sunburst, deep blue/black space, city-light transition |
| `grok_video_2026-08-23-21-42-08.mp4` | Night | Dark planet with concentrated golden city lights and deep space |

Use the device/browser's local timezone (`DateTime.now()` in Flutter and `new Date()` in the WebView). Slot boundaries: morning 05:00–11:59, afternoon 12:00–16:59, evening 17:00–20:59, night 21:00–04:59. Keep the video visible with `object-fit: cover`/`BoxFit.cover`, a readable scrim, autoplay, muted, loop, and playsInline behavior.
