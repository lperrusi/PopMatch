# Hot Reload Guide for PopMatch

## The Issue
Hot reload requires Flutter to be running in an **interactive terminal session**. When the app runs in the background, hot reload commands cannot be sent.

## Solution: Run the App in Your Terminal

### Option 1: Use the Run Script (Recommended)

1. **Open a terminal** in your project directory:
   ```bash
   cd /Users/lucasperrusi/Projects/PopMatch
   ```

2. **Run the app script**:
   ```bash
   ./run_app.sh
   ```

   Or run directly with the device ID:
   ```bash
   flutter run -d "877A2EF2-A809-4F75-9995-9C5C9C5F8DC9"
   ```

3. **Wait for the app to build and launch** - you'll see output like:
   ```
   Launching lib/main.dart on iPhone 16 Plus in debug mode...
   Running Xcode build...
   ```

4. **Once the app is running**, you'll see a prompt like:
   ```
   Flutter run key commands.
   r Hot reload. 🔥🔥🔥
   R Hot restart.
   h List all available interactive commands.
   ```

### Option 2: Use Flutter's Hot Reload Commands

Once the app is running in your terminal:

- **Hot Reload**: Press `r` in the terminal (for small changes like UI tweaks)
- **Hot Restart**: Press `R` in the terminal (for state changes or larger updates)
- **Full Restart**: Press `q` to quit, then run again

## Troubleshooting

### If Hot Reload Still Doesn't Work:

1. **Check if the app is actually running**:
   ```bash
   ps aux | grep "flutter run"
   ```

2. **Try a hot restart instead** (press `R` in the terminal):
   - This fully restarts the app but keeps the same session

3. **If that doesn't work, do a full rebuild**:
   - Press `q` to quit
   - Run `flutter clean`
   - Run `flutter pub get`
   - Run the app again

4. **Check for compilation errors**:
   ```bash
   flutter analyze
   ```
   Fix any errors before hot reload will work

### Common Hot Reload Issues:

- **State changes**: Hot reload preserves state. Use Hot Restart (`R`) instead
- **Asset changes**: Changes to assets require a full restart
- **Native code changes**: Changes to iOS/Android native code require a full rebuild
- **Initialization changes**: Changes to `main()` require a full restart

## Quick Reference

| Action | Command |
|--------|---------|
| Hot Reload | Press `r` in terminal |
| Hot Restart | Press `R` in terminal |
| Full Restart | Press `q`, then run again |
| Check Errors | `flutter analyze` |
| Clean Build | `flutter clean && flutter pub get` |

## After Making Changes

1. Save your file
2. Press `r` in the terminal where Flutter is running
3. Wait for "Reloaded X of Y libraries" message
4. Check the simulator/device to see changes

---

**Important**: The app MUST be running in YOUR terminal for hot reload to work. Background processes don't support interactive hot reload commands.

