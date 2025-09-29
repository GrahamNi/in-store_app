# HANDOVER DOCUMENT - Label Scanner Project
## Date: September 29, 2025
## Current Status: BUILD WORKING, STORES LOADING FROM API ✅

---

## CRITICAL CONTEXT

### What This App Does
- **In-store label scanning app** for FMCG data collection
- **Two user profiles:**
  - Profile A (In-Store): Direct to camera for label capture
  - Profile B (In-Store Promo): Store → Location Selection → Camera
- **Workflow:** Download all stores on login → Cache locally → Calculate nearest 5 using phone GPS

### Project Location
- **Main Project:** `C:\dev\label_scanner`
- **Flutter SDK:** `C:\Users\Dtex Admin PC\OneDrive - DTex Digital Data Collection\Desktop\flutter`
- **Android SDK:** `C:\Users\Dtex Admin PC\AppData\Local\Android\sdk`

---

## ✅ WHAT WAS FIXED TODAY (Sept 29, 2025)

### 1. Build Compilation Issues (FIXED)
**Problem:** Gradle build failing with circular reference error
**Solution:** Fixed `android/build.gradle.kts` with correct Kotlin DSL syntax:
```kotlin
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
```

### 2. Store API Integration (FIXED)
**Problem:** Stores showing "Demo Data" instead of loading from API
**Root Cause:** API requires POST with lat/lon, code was using GET
**Solution:** Changed `StoreServiceFixed.downloadAllStores()` to use POST:
```dart
final response = await _dio.post(
  _storesApiUrl,
  data: {'lat': -32.9273, 'lon': 151.7817},  // Default location
```

**API Response Structure:**
```json
{
  "count": 11,
  "limit": 100000,
  "results": [
    {
      "id": 37013,
      "name": "New World New Plymouth",
      "lat": -39.0578,
      "lon": 174.0777,
      "distance_km": 2112.0478,
      "extra": {
        "address_1": "78 Courtenay Street",
        "city": "New Plymouth",
        "state": "North Island"
      }
    }
  ]
}
```

### 3. Fake Test Data Removed (FIXED)
**Problem:** Location selection showing fake "completed" aisles
**Solution:** Removed `_loadMockProgress()` method, replaced with `_loadRealProgress()`

---

## 🔧 WHAT STILL NEEDS WORK

### 1. Store Logo Display
**Issue:** Logos not showing for New World stores
**Next Step:** User is adding `newworld_logo.png` to assets folder
**File to update:** `lib/store_selection_screen.dart` - `_getStoreLogo()` method needs New World case

### 2. Real Progress Tracking
**Issue:** Visit progress not persisted to database
**Current:** Progress tracked in memory only (lost when app closes)
**Next Step:** Implement database persistence in `_loadRealProgress()` and `_onCaptureComplete()`

### 3. Camera Screen Testing
**Status:** Not tested yet
**Next Step:** Test scene capture → label capture workflow

---

## 📁 KEY FILES AND THEIR PURPOSE

### Store Management
- **`lib/services/store_service_fixed.dart`** - Handles API calls, caching, distance calculation
  - `downloadAllStores()` - POST to API, returns all stores
  - `getNearestStores()` - Uses cached stores, calculates distances locally
  - `updateStoresIfNeeded()` - Checks if cache is >1 hour old

- **`lib/store_selection_screen.dart`** - Store selection UI
  - Shows nearest 5 stores with distances
  - API status indicator (green = live, orange = demo)

### Navigation
- **`lib/main_navigation_wrapper.dart`** - Bottom navigation (Store/Queue/Settings)
  - ALL users get Profile B navigation (no home screen)

### Location Selection
- **`lib/enhanced_location_selection_screen.dart`** - Installation type selection
  - Grid of installation types (End, Front, Freezer, Deli, etc.)
  - Shows completion progress (now starts at 0/20, not fake data)
  - Opens aisle selection modal for aisle-based installations

### Camera
- **`lib/camera_screen.dart`** - Camera capture with ML
  - Scene capture mode (wide shot)
  - Label capture mode (close-up)

---

## 🚀 HOW TO RUN

```bash
# From C:\dev\label_scanner
flutter clean
flutter run
```

---

## 🐛 KNOWN ISSUES

### Disk Space
- C: drive was full earlier today - caused build failures
- If builds fail, run: `flutter clean` and check available space

### Gradle Memory
- Set to 2GB in `android/gradle.properties`
- Don't increase to 8GB (causes issues)

### Dependencies
- 21 packages have outdated versions (non-critical)
- Run `flutter pub outdated` to see list

---

## 📊 API CONFIGURATION

### Store API Endpoint
- **URL:** `https://api-nearest-stores-951551492434.australia-southeast1.run.app/`
- **Method:** POST (not GET!)
- **Body:** `{"lat": <number>, "lon": <number>}`
- **Response:** Map with "results" key containing store array
- **Cache Duration:** 1 hour (configurable in `store_service_fixed.dart`)

---

## 🎯 NEXT STEPS (Priority Order)

1. **Test camera functionality** - Verify scene → label capture works
2. **Add New World logo** - User is handling this
3. **Implement progress persistence** - Save to database, not just memory
4. **Test upload queue** - Verify background sync works
5. **Test full workflow end-to-end** - Store selection → location → camera → upload

---

## ⚠️ IMPORTANT NOTES

### Don't Touch These Files Unless Necessary
- `android/build.gradle.kts` - JUST FIXED, works now
- `android/gradle.properties` - Memory settings are correct
- `lib/main_navigation_wrapper.dart` - Navigation is correct

### User's Workflow Understanding
User confirmed the API workflow:
1. Download ALL stores on first login (driven by server profile)
2. Check for updates each time user opens store screen (only if >1 hour old)
3. If no network, use cached stores
4. Use phone GPS to calculate nearest 5 stores locally

### Build Time
- First build: 5-15 minutes (normal)
- Subsequent builds: 2-3 minutes
- If taking longer, might be stuck - check Task Manager for Java/Gradle processes

---

## 📞 USER CONTEXT

- Patient is wearing thin after 5 hours of debugging
- Prefers direct fixes over explanations
- Wants memory checks before major operations
- Device: Blade A52 Pro Android phone
- Location: Australia (Sydney timezone)

---

## 🔍 DEBUG TIPS

### Check Store Loading
Look for these console messages:
```
📥 STORE SERVICE: Found results key with X stores
✅ STORE SERVICE: Downloaded X stores
💾 STORE SERVICE: Cached X stores
📍 STORE SERVICE: Returning 5 nearest stores
```

### Check Build Issues
If build fails, check:
1. Disk space: `Get-PSDrive C`
2. Gradle processes: Task Manager → Java processes
3. Clean and retry: `flutter clean && flutter run`

---

**STATUS: Ready for camera testing and progress persistence implementation**
