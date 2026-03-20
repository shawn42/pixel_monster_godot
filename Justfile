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

# Export iOS Xcode project (may fail on signing but generates the project)
export-ios:
    mkdir -p ios
    godot --path . --headless --export-debug "iOS" ios/PixelMonster.ipa || true
    @test -d ios/PixelMonster.xcodeproj && echo "Xcode project generated" || (echo "Export failed" && exit 1)
    sed -i '' 's/CODE_SIGN_IDENTITY = "Apple Distribution"/CODE_SIGN_IDENTITY = "Apple Development"/g' ios/PixelMonster.xcodeproj/project.pbxproj

# Build and install on connected iOS device (requires: brew install ios-deploy)
deploy-ios: export-ios
    rm -rf ios/build
    xcodebuild -project ios/PixelMonster.xcodeproj \
        -scheme PixelMonster \
        -sdk iphoneos \
        -configuration Debug \
        DEVELOPMENT_TEAM=4Q9YT4FMZL \
        OTHER_LDFLAGS='$$(inherited) -lswift_Concurrency' \
        -allowProvisioningUpdates \
        -derivedDataPath ios/build
    ios-deploy --bundle $(find ios/build -name "PixelMonster.app" -path "*/Debug-iphoneos/*" | head -1) --no-wifi

# Export macOS app (.dmg)
export-mac:
    godot --path . --headless --export-debug "macOS" PixelMonster.dmg

# Run macOS app
run-mac: export-mac
    open PixelMonster.dmg

# Export Windows exe (cross-compiled)
export-windows:
    godot --path . --headless --export-debug "Windows" PixelMonster.exe

# Export Linux binary (cross-compiled)
export-linux:
    godot --path . --headless --export-debug "Linux" PixelMonster.x86_64

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
    rm -f PixelMonster.dmg PixelMonster.exe PixelMonster.x86_64
    rm -rf web/ ios/

# Validate scenes can be parsed (headless import)
validate:
    godot --path . --headless --import
