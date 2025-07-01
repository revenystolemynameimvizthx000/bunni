#!/bin/bash

main() {
    echo "--- BUNNI MAC INSTALLER ---"

    echo "Getting latest Mac Version"
    # Teste den JSON-Parsing Teil einzeln
    json=$(curl -s "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
    echo "Raw JSON: $json"
    
    # Teste den grep Befehl
    version=$(echo "$json" | grep -o '"clientVersionUpload":"[^"]*' | grep -o '[^"]*$')
    echo "Extracted version: '$version'"
    
    # Vergleiche
    if [ "$version" = "version-db859ae17f144eea" ]; then
        echo "Version matches!"
    else
        echo "Version does not match. Expected: version-db859ae17f144eea, Got: '$version'"
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

    echo "Installation complete."
}

main
