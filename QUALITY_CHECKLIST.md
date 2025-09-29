# 🔍 Flutter Code Quality Checklist

## Before Making Major Changes:

### ✅ **Pre-Change Validation**
- [ ] Run `scripts\validate.bat` to check current state
- [ ] Create a git commit of working state: `git add . && git commit -m "Working state before changes"`
- [ ] Document what you're about to change

### ✅ **While Making Changes**
- [ ] Make changes incrementally (one feature at a time)
- [ ] Test compilation after each major change: `flutter run -d chrome --hot-reload`
- [ ] Use descriptive variable/class names that match their purpose
- [ ] Import statements at the top, organize by: dart libraries, flutter, external packages, internal files

### ✅ **Common Pitfalls to Avoid**

#### **Import Issues:**
- [ ] Check all imports are correct paths
- [ ] Verify no circular imports (A imports B, B imports A)
- [ ] Use relative imports for internal files: `import '../models/app_models.dart'`

#### **Enum Issues:**
- [ ] Use existing enums instead of creating new ones
- [ ] Check enum values match across all files
- [ ] Search for old enum references when changing: `Ctrl+Shift+F`

#### **Constructor Issues:**
- [ ] Check required parameters match when calling constructors
- [ ] Verify parameter types match expected types
- [ ] Use named parameters consistently

#### **Type Issues:**
- [ ] Check null safety - use `?` for nullable types
- [ ] Verify generic types match: `List<String>` not `List<dynamic>`
- [ ] Cast types when necessary: `value as String`

### ✅ **After Making Changes**
- [ ] Run `flutter analyze` to check for warnings
- [ ] Run `flutter run -d chrome` to test compilation
- [ ] Test the feature you just changed
- [ ] Commit working changes: `git add . && git commit -m "Feature: description"`

### ✅ **If Compilation Fails**
1. **Read the error message carefully** - it usually tells you exactly what's wrong
2. **Check the file and line number** mentioned in the error
3. **Look for these common issues:**
   - Missing imports
   - Typos in class/variable names
   - Wrong parameter types
   - Missing required parameters
   - Enum value mismatches
4. **Use "Find in Files" (Ctrl+Shift+F)** to locate all references to problematic code
5. **If stuck, revert to last working commit:** `git checkout -- .`

### ✅ **Emergency Recovery**
If everything breaks:
```bash
git status                    # See what changed
git checkout -- .            # Revert all changes
flutter clean                # Clean project
flutter pub get              # Restore dependencies
flutter run -d chrome        # Test that it works
```

## 🎯 **Quick Reference Commands**

| Task | Command |
|------|---------|
| Quick validation | `scripts\validate.bat` |
| Check for errors | `flutter analyze` |
| Test compilation | `flutter run -d chrome` |
| Find text in all files | `Ctrl+Shift+F` (in VS Code) |
| Revert all changes | `git checkout -- .` |
| Clean project | `flutter clean && flutter pub get` |

## 🚨 **Red Flags - Stop and Check**
- Changing enum definitions
- Adding new dependencies  
- Modifying constructor parameters
- Creating new imports between existing files
- Mass find-and-replace operations
