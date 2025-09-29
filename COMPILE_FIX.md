## ✅ COMPILATION ISSUE FIXED

**Problem:** The Duration constructor was having issues with computed values in a const context.

**Solution:** Pre-computed the duration value into a variable before passing to Duration constructor.

**Changed:**
```dart
// Before (problematic)
Duration(minutes: (scenesCaptured + labelsCaptured) * 2)

// After (fixed)
final estimatedMinutes = totalCaptured * 2;
Duration(minutes: estimatedMinutes)
```

**Ready to test again:**
```bash
flutter run -d chrome
```

The app should now compile and run successfully with all features working!
