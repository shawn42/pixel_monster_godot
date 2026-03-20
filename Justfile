# Pixel Monster - Godot 4.6 project tasks

# Run the game
run:
    godot --path . scenes/MainMenu.tscn

# Run starting at a specific level (0-based index)
run-level level="0":
    godot --path . scenes/Game.tscn -- --level {{level}}

# Open the project in the Godot editor
edit:
    godot --path . --editor &

# Export Android APK
export-android:
    godot --path . --headless --export-debug "Android" pixel-monster.apk

# Install APK on connected Android device
install: export-android
    adb install -r pixel-monster.apk

# Run on connected Android device (install + launch)
deploy: install
    adb shell am start -n com.shawn42.pixelmonster/com.godot.game.GodotApp

# List all level PNGs
levels:
    @ls -1 levels/*.png | sort -V

# Count lines of GDScript
loc:
    @find scripts -name '*.gd' | xargs wc -l | tail -1

# Export iOS Xcode project
export-ios:
    mkdir -p ios
    godot --path . --headless --export-debug "iOS" ios/PixelMonster.ipa

# Run in iOS Simulator (default: iPhone 17 Pro)
# Requires App Store Team ID in export_presets.cfg
sim-ios device="iPhone 17 Pro": export-ios
    xcrun simctl boot "{{device}}" 2>/dev/null || true
    open -a Simulator
    xcrun simctl install "{{device}}" ios/PixelMonster.ipa
    xcrun simctl launch "{{device}}" com.shawn42.pixelmonster

# Build and run on connected iOS device (requires ios-deploy: brew install ios-deploy)
deploy-ios: export-ios
    ios-deploy --bundle ios/PixelMonster.ipa --debug

# Export Web build
export-web:
    mkdir -p web
    godot --path . --headless --export-debug "Web" web/index.html

# Serve web build locally
serve: export-web
    @echo "Serving at http://localhost:8060"
    python3 -m http.server 8060 --directory web

# Clean build artifacts
clean:
    rm -f pixel-monster.apk pixel-monster.apk.idsig
    rm -rf web/ ios/

# Validate scenes can be parsed (headless import)
validate:
    godot --path . --headless --import
