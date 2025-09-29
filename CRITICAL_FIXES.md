# CRITICAL FIXES - ALL THREE ISSUES

## Issue 1: Profile B Users Getting HOME Screen
**Problem:** main_navigation_wrapper.dart lines 104-109 show InStoreMode gets HOME + 4 tabs
**Root Cause:** The force-set in main.dart might not be propagating

## Issue 2: Stores Still Showing Mock Data  
**Problem:** StoreServiceFixed.getNearestStores() returns empty array
**Root Cause:** The API call or caching logic is failing silently

## Issue 3: Camera Disabled
**Problem:** Camera not starting
**Possible Cause:** Permission issues OR navigation state corruption from Issue #1

## IMMEDIATE ACTION REQUIRED:

1. Verify the UserProfile.userType is ACTUALLY being set to inStorePromo
2. Check StoreServiceFixed to see why it returns empty
3. Check camera permissions in AndroidManifest.xml

Let me check these NOW:
