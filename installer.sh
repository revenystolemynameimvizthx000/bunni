#!/bin/bash
main() {
    echo "--- BUNNI MAC INSTALLER ---"
    echo "Getting latest Mac Version"
    json=$(curl -s "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
    local version=$(echo "$json" | grep -o '"clientVersionUpload":"[^"]*' | grep -o '[^"]*$')
    if [ "$version" != "version-db859ae17f144eea" ]; then
        echo "Bunni Mac is not updated for the latest Version. Stopping Installation"
        exit 1
    fi
    if pgrep -x "RobloxPlayer" > /dev/null; then
        pkill -9 RobloxPlayer
    fi
    echo "Reinstalling Roblox"
    [ -d "/Applications/Roblox.app" ] && rm -rf "/Applications/Roblox.app"
    curl -L "http://setup.rbxcdn.com/mac/$version-RobloxPlayer.zip" -o "./RobloxPlayer.zip"
    unzip -o -q "./RobloxPlayer.zip"
    mv "./RobloxPlayer.app" "/Applications/Roblox.app"
    rm "./RobloxPlayer.zip"
    xattr -c /Applications/Roblox.app
    codesign --remove-signature "/Applications/Roblox.app/Contents/MacOS/RobloxPlayer"
    if [ -d "/Applications/Bunni.app" ]; then
        echo "Deleting existing Bunni.app..."
        rm -rf "/Applications/Bunni.app"
    fi
    echo "Downloading Bunni UI..."
    curl -L "https://raw.githubusercontent.com/revenystolemynameimvizthx000/bunni/refs/heads/main/Bunni_0.1.0_universal.dmg" -o "./Bunni.dmg"
    echo "Starting DMG..."
    MOUNT_OUTPUT=$(hdiutil attach "./Bunni.dmg" -nobrowse)
    MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/[^ ]*')
    if [ -z "$MOUNT_POINT" ]; then
        echo "Failed to mount DMG."
        exit 1
    fi
    echo "Opening Finder window..."
    open "$MOUNT_POINT"
    echo "Waiting for user to finish installation..."
    while [ ! -d "/Applications/Bunni.app" ]; do
        sleep 2
    done
    echo "Downloading dylib..."
    curl -L "https://raw.githubusercontent.com/revenystolemynameimvizthx000/bunni/refs/heads/main/libbunnimac.dylib" -o "./libbunnimac.dylib"
    echo "Installing dylib into Bunni.app..."
    LIB_TARGET="/Applications/Roblox.app/Contents/MacOS/libbunnimac.dylib"
    cp "./libbunnimac.dylib" "$LIB_TARGET"
    chmod +x "$LIB_TARGET"
    echo "Cleaning up..."
    hdiutil detach "$MOUNT_POINT" -quiet
    rm "./Bunni.dmg"
    rm "./libbunnimac.dylib"
    
    # Check and install lz4 if needed
    echo "Checking for lz4..."
    if ! command -v lz4 &> /dev/null; then
        echo "lz4 not found. Checking for Homebrew..."
        if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Installing..."
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        echo "Installing lz4..."
        brew install lz4
    else
        echo "lz4 is already installed."
    fi
    
    # Download and extract dependencies
    echo "Downloading dependencies..."
    curl -L "https://raw.githubusercontent.com/revenystolemynameimvizthx000/bunni/refs/heads/main/dependencies.7z" -o "./dependencies.7z"
    
    # Check if 7z is available
    if ! command -v 7z &> /dev/null; then
        echo "7z not found. Installing p7zip..."
        brew install p7zip
    fi
    
    # Extract dependencies to Roblox folder
    DEPS_TARGET="/Applications/Roblox.app/Contents/MacOS/dependencies"
    echo "Extracting dependencies to $DEPS_TARGET..."
    mkdir -p "$DEPS_TARGET"
    7z x "./dependencies.7z" -o"$DEPS_TARGET" -y
    
    # Clean up
    rm "./dependencies.7z"
    
    echo "Installation complete."
}
main
