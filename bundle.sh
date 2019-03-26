#!/bin/bash

set -e

mkdir -p exports
EXPORT_FOLDER="$(readlink -f exports)"
SRC_FOLDER="$(readlink -f src)"

# Guide through exporting game

check_for() {
    echo "Checking for $1 ..."
    if ! [ "$(command -v $1)" ]; then
        echo "$1 not found! Exiting ..."
        exit 1
    fi
}

find_dir() {
    echo "Checking for $1 directory ..."
    if ! [ -d "$1" ]; then
        echo "$1 directory not found! Exiting ..."
        exit 1
    fi
}

check_for "xclip"
check_for "zip"
check_for "rm"
check_for "pwd"
check_for "godot"

find_dir "$EXPORT_FOLDER"
find_dir "$SRC_FOLDER"

echo "Deleting $EXPORT_FOLDER/ ..."
rm -r $EXPORT_FOLDER
echo "Creating $EXPORT_FOLDER/ ..."
mkdir "$EXPORT_FOLDER"
cd "$EXPORT_FOLDER"
echo "Copying $EXPORT_FOLDER path to clipboard ..."
pwd | xclip -selection c
cd ..
#echo "Please export game to path in clipboard, then press any key to continue ..."
#read -n1 -s
read -p "Game Executable Name   : " GAME_NAME
read -p "Export Type            : " EXPORT_TYPE
read -p "Version                : " GAME_VERSION
echo "Exporting ..."
cd "$SRC_FOLDER"
godot --export "$EXPORT_TYPE" "$EXPORT_FOLDER/$GAME_NAME"
cd "$EXPORT_FOLDER"
zip "${GAME_NAME}-${EXPORT_TYPE}v${GAME_VERSION}.zip" *
echo "Done"
