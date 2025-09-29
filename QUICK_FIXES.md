# 🚨 Flutter Compilation Quick Fixes

## Common Error Patterns & Solutions

### **"The getter 'X' isn't defined for the type 'Y'"**

**Cause:** Missing import or typo in class/variable name

**Fix:**
1. Check if the class is imported: `import 'path/to/file.dart';`
2. Verify spelling of the variable/method name
3. Check if it's a static method: `ClassName.methodName` vs `instance.methodName`

**Example:**
```dart
// ❌ Error: CameraMode not imported
mode: CameraMode.sceneCapture

// ✅ Fix: Add import
import 'models/app_models.dart';
mode: CameraMode.sceneCapture
```

### **"The argument type 'X' can't be assigned to parameter type 'Y'"**

**Cause:** Parameter type mismatch

**Fix:**
1. Check the constructor/method signature
2. Verify parameter types match
3. Cast if necessary: `value as TargetType`

**Example:**
```dart
// ❌ Error: Missing required parameter
CameraScreen(storeId: '123', storeName: 'Store')

// ✅ Fix: Add required parameter
CameraScreen(storeId: '123', storeName: 'Store', mode: CameraMode.labelCapture)
```

### **"Missing concrete implementation of getter/setter/method"**

**Cause:** Abstract method not implemented or typo in override

**Fix:**
1. Implement the missing method
2. Check spelling of overridden methods
3. Verify method signature matches parent class

### **"The name 'X' isn't defined"**

**Cause:** Typo, missing import, or undefined variable

**Fix:**
1. Check spelling
2. Add missing import
3. Define the variable/constant

### **"Circular import dependency"**

**Cause:** File A imports B, File B imports A

**Fix:**
1. Move shared code to a separate file
2. Use forward declarations if possible
3. Restructure imports to avoid cycles

### **"Expected ';' after this"**

**Cause:** Missing semicolon or incorrect syntax

**Fix:**
1. Add missing semicolon
2. Check parentheses matching: `()`, `{}`, `[]`
3. Verify comma placement in lists

## 🔧 Emergency Procedures

### **If Multiple Errors Appear:**
1. **Fix the FIRST error only** - others might be cascading
2. Save file and check if other errors disappear
3. Repeat until all errors are gone

### **If Completely Stuck:**
```bash
# 1. See what you changed
git status

# 2. Revert everything to last working state
git checkout -- .

# 3. Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome

# 4. Make changes again, but smaller increments
```

### **If Import Errors:**
```bash
# Quick fix - organize all imports
# In VS Code: Ctrl+Shift+P -> "Dart: Organize Imports"
```

### **If Pub Get Errors:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

## 🎯 Prevention Rules

1. **One change at a time** - Don't modify multiple files simultaneously
2. **Test after each change** - `flutter run -d chrome` frequently
3. **Read error messages** - They usually tell you exactly what's wrong
4. **Use Find in Files** - Ctrl+Shift+F to find all references before changing
5. **Commit frequently** - Every working state should be saved

## 📝 Error Message Translation

| Error Message | Translation | Quick Fix |
|---------------|-------------|-----------|
| "isn't defined for type" | Missing import or typo | Add import or fix spelling |
| "can't be assigned to parameter" | Wrong type | Check parameter types |
| "Missing required parameter" | Constructor needs more parameters | Add missing parameters |
| "Expected ';'" | Syntax error | Check punctuation |
| "Circular import" | Files import each other | Restructure imports |
