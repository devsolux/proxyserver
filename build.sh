#!/bin/sh

# Set exit on error.
set -e

#
# Basic Prep...
#

TIME_START=$(date +%s)

fcomplete() {
  TIME_END=$(date +%s)
  TIME_TAKEN=$(( TIME_END - TIME_START ))

  echo "Done (${TIME_TAKEN}s)."
  exit 0
}

# Ensure the user is in the correct directory (the directory containing this script.)
if [ "$(pwd)" != "${0%/*}" ]; then
  cd "${0%/*}" || exit
fi

. ./version.properties

#
# Print Banner
#
printf "v%s -- a DevSolux Project - https://devsolux.com/\n" "$VERSION_NAME";
printf "\n";
printf "\n";

#
# Start Build Script
#

if [ $# -lt 1 ]; then
  printf "Usage: %s <darwin|linux|windows> [<server|desktop>]   -  Builds Proxyserver for the given platform.\n" "$0"
  printf "Usage: %s clean                                       -  Cleans the out/ directory.\n" "$0"
  exit 3
fi

#
# COMMAND: clean
#
if [ "$1" = "clean" ]; then
  echo "Cleaning build directory..."
  rm -rf ./out/*

  echo "Cleaning left over build files..."
  [ -f "icons/icon_unix.go" ] && rm icons/icon_unix.go
  [ -f "icons/icon_win.go" ] && rm icons/icon_win.go

  [ -f "rsrc.syso" ] && rm rsrc.syso

  fcomplete
  exit 0
fi

#
# COMMAND: publish
#
if [ "$1" = "publish" ]; then
  RELEASE_TAG_NAME="v$VERSION_NAME"

  CONFIRMED=0
  case "$@[@]" in *"-c"*) CONFIRMED=1 ;; esac

  echo "Validating..."
  if GIT_DIR=./.git git rev-parse "$RELEASE_TAG_NAME" >/dev/null 2>&1; then
      echo "Version $VERSION_NAME already exists! (perhaps you need to bump version name and code.)"
      exit 1
  fi

  echo "Validation succeeded."
  echo ""


  if [ "$CONFIRMED" -ne 1 ]; then
    echo "========================================"
    echo "You are preparing the following release:"
    echo "========================================"
    echo ""
    printf "Version Name:\t\t%s\n" "$VERSION_NAME"
    printf "Version Code:\t\t%s\n" "$VERSION_CODE"
    echo ""
    echo "Before pushing, please ensure you have:"
    echo "- tested your build thoroughly on"
    echo "  all supported systems."
    echo "- sufficiently selected and/or bumped"
    echo "  the version number for your release."
    echo ""
    echo ""
    echo "To confirm you have done this, please"
    echo "run the same command again, specifying"
    echo "-c."
    exit 0
  fi

  echo "Preparing new release..."
  git tag -a "$RELEASE_TAG_NAME"

  echo "Pushing release..."
  git push origin "$RELEASE_TAG_NAME"

  exit 0
fi

#
# COMMAND: unpublish
#
if [ "$1" = "unpublish" ]; then
  echo "Fetching all releases..."
  git fetch

  RELEASE_TAG_NAME="v$VERSION_NAME"

  CONFIRMED=0
  case "$@[@]" in *"-c"*) CONFIRMED=1 ;; esac

  echo "Validating..."
  if ! GIT_DIR=./.git git rev-parse "$RELEASE_TAG_NAME" >/dev/null 2>&1; then
      echo "Version $VERSION_NAME doesn't exist."
      exit 1
  fi

  echo "Validation succeeded."
  echo ""


  if [ "$CONFIRMED" -ne 1 ]; then
    echo "=============================================="
    echo "You are about to remove the following release:"
    echo "=============================================="
    echo ""
    printf "Published Tag:\t\t%s\n" "$RELEASE_TAG_NAME"
    printf "Version Name:\t\t%s\n" "$VERSION_NAME"
    printf "Version Code:\t\t%s\n" "$VERSION_CODE"
    echo ""
    echo "To confirm you wish to proceed, please run the"
    echo "same command again, specifying -c."
    exit 0
  fi

  echo "Unpublishing release."
  git tag -d "$RELEASE_TAG_NAME"
  git push origin ":refs/tags/$RELEASE_TAG_NAME"

  exit 0
fi

#
# COMMAND (implicit): build
#

# Collect parameters.
PLATFORM="$1"
BUILD_TYPE="$2"

# Ensure that a valid OS/platform has been selected.
if [ "$PLATFORM" != "darwin" ] && [ "$PLATFORM" != "linux" ] && [ "$PLATFORM" != "windows" ]; then
	echo "Invalid platform selected ($PLATFORM). It must be one of <darwin|linux|windows>."
	exit 4
fi

# Ensure that a valid build type has been selected.
if [ $# -lt 2 ]; then
	BUILD_TYPE="desktop"
elif [ "$BUILD_TYPE" != "desktop" ] && [ "$BUILD_TYPE" != "server" ]; then
	echo "Invalid build type selected ($BUILD_TYPE). It must be one of <server|desktop>."
	exit 5
fi


# We're running a build.
echo "Building Proxyserver $BUILD_TYPE v$VERSION_NAME (build $VERSION_CODE) for $PLATFORM..."
echo ""
echo ""


# Ensure output directory exists.
[ -d "out/" ] || mkdir "out/"
[ -d "out/$PLATFORM-$BUILD_TYPE" ] && rm -r "out/$PLATFORM-$BUILD_TYPE"
mkdir "out/$PLATFORM-$BUILD_TYPE"
OUTPUT_DIR="out/$PLATFORM-$BUILD_TYPE"


# Handle special build: server
if [ "$BUILD_TYPE" = "server" ]; then
  echo "Executing go build..."

	if [ "$PLATFORM" = "windows" ]; then
		GOOS="$PLATFORM" GOARCH="amd64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/proxyserver-server.exe" server/server.go
	  mv "$OUTPUT_DIR/proxyserver-server.exe" "$OUTPUT_DIR/proxyserver-server-windows-amd64-v${VERSION_NAME}.exe"

	  GOOS="$PLATFORM" GOARCH="arm64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/proxyserver-server.exe" server/server.go
    mv "$OUTPUT_DIR/proxyserver-server.exe" "$OUTPUT_DIR/proxyserver-server-windows-arm64-v${VERSION_NAME}.exe"

    # echo "Compressing release binary..."
    # WORKING_DIR=$(pwd)
    # cd "$OUTPUT_DIR" || exit 1
	  # zip -r "proxyserver-server-windows-v${VERSION_NAME}.zip" "proxyserver-server-windows-v${VERSION_NAME}.exe"
	  # cd "$WORKING_DIR" || exit 1
	else
		GOOS="$PLATFORM" GOARCH="amd64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/proxyserver-server" server/server.go
	  mv "$OUTPUT_DIR/proxyserver-server" "$OUTPUT_DIR/proxyserver-server-${PLATFORM}-amd64-v${VERSION_NAME}"

    # Only run arm64 build for Darwin non-windows.
    # TODO: Linux arm64?
    if [ "$PLATFORM" = "darwin" ]; then
      GOOS="$PLATFORM" GOARCH="arm64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/proxyserver-server" server/server.go
      mv "$OUTPUT_DIR/proxyserver-server" "$OUTPUT_DIR/proxyserver-server-${PLATFORM}-arm64-v${VERSION_NAME}"
    fi

	  # echo "Compressing release binary..."
	  # WORKING_DIR=$(pwd)
    # cd "$OUTPUT_DIR" || exit 1
	  # zip -r "proxyserver-server-${PLATFORM}-v${VERSION_NAME}.zip" "proxyserver-server-${PLATFORM}-v${VERSION_NAME}"
	  # cd "$WORKING_DIR" || exit 1
	fi
	exit
fi


# Remove all legacy icons.
[ -f icons/icon_unix.go ] && rm icons/icon_unix.go
[ -f icons/icon_win.go ] && rm icons/icon_win.go


# Build the icon for the appropriate platform.
echo "Generating platform icon..."
go get github.com/cratonica/2goarray
if [ "$PLATFORM" = "darwin" ] || [ "$PLATFORM" = "linux" ]; then
  cat "icons/icon.png" | go run github.com/cratonica/2goarray Data icon >> icons/icon_unix.go
elif [ "$PLATFORM" = "windows" ]; then
  cat "icons/icon.ico" | go run github.com/cratonica/2goarray Data icon >> icons/icon_win.go
else
  echo "Unknown platform: $1"
  exit 3
fi


# Copy binary assets.
echo "Copying binary assets..."
cp -r "resources/$PLATFORM/." "$OUTPUT_DIR/"


# Inject placeholders into assets.
echo "Injecting placeholders into binary assets..."
find "$OUTPUT_DIR" -type f -print0 | xargs -0 perl -pi -e "s/\\\$VERSION_NAME/$VERSION_NAME/g"
find "$OUTPUT_DIR" -type f -print0 | xargs -0 perl -pi -e "s/\\\$VERSION_CODE/$VERSION_CODE/g"


# Execute platform build.
echo "Executing go build..."

if [ "$PLATFORM" = "darwin" ]; then
  mkdir -p "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS"
  mkdir -p "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/icons"
  cp icons/icon.png "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/icons/"

  # Build amd64 (Intel) macOS binary.
  CGO_ENABLED=1 GOOS="darwin" GOARCH="amd64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver-amd64"

  # Build arm64 (Apple Silicon) macOS binary.
  CGO_ENABLED=1 GOOS="darwin" GOARCH="arm64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver-arm64"

  # Use `lipo` to merge the binaries into a universal binary.
  lipo -create -output "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver" "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver-amd64" "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver-arm64"

  # Remove individual binaries to leave just universal binary.
  rm "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver-amd64"
  rm "$OUTPUT_DIR/Proxyserver.app/Contents/MacOS/proxyserver-arm64"

  # Produce output bundles
  mv "$OUTPUT_DIR/Proxyserver.app" "$OUTPUT_DIR/Proxyserver-Desktop-macOS-v${VERSION_NAME}.app"

  # Compressing output bundles
  echo "Compressing output bundles"

  WORKING_DIR=$(pwd)
  cd "$OUTPUT_DIR" || exit 1
  zip -r "Proxyserver-Desktop-macOS-v${VERSION_NAME}.zip" "Proxyserver-Desktop-macOS-v${VERSION_NAME}.app"

  cd "$WORKING_DIR" || exit 1
elif [ "$PLATFORM" = "windows" ]; then
  [ -f "rsrc.syso" ] && rm rsrc.syso
  go get github.com/akavel/rsrc
  go install github.com/akavel/rsrc

  rsrc -arch="amd64" -manifest="$OUTPUT_DIR/proxyserver.manifest" -ico="icons/icon.ico" -o rsrc.syso
  CGO_ENABLED=1 GOOS="windows" GOARCH="amd64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE -H=windowsgui" -o "$OUTPUT_DIR/proxyserver-amd64.exe"
  rm rsrc.syso

  rsrc -arch="arm64" -manifest="$OUTPUT_DIR/proxyserver.manifest" -ico="icons/icon.ico" -o rsrc.syso
  CGO_ENABLED=1 GOOS="windows" GOARCH="arm64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE -H=windowsgui" -o "$OUTPUT_DIR/proxyserver-arm64.exe"
  rm rsrc.syso

  mkdir "$OUTPUT_DIR/icons"
  cp icons/icon.png "$OUTPUT_DIR/icons/icon.png"

  mkdir "$OUTPUT_DIR/data"

  rm "$OUTPUT_DIR/proxyserver.manifest"

  mv "$OUTPUT_DIR/proxyserver-amd64.exe" "$OUTPUT_DIR/Proxyserver-Desktop-Windows-amd64-v${VERSION_NAME}.exe"
#  mv "$OUTPUT_DIR/proxyserver-arm64.exe" "$OUTPUT_DIR/Proxyserver-Desktop-Windows-arm64-v${VERSION_NAME}.exe"

  # Compressing output bundles
  echo "Compressing output bundles"

  # WORKING_DIR=$(pwd)
  # cd "$OUTPUT_DIR" || exit 1
  # zip -r "Proxyserver-Windows-v${VERSION_NAME}.zip" "Proxyserver-Windows-v${VERSION_NAME}.exe"
  # cd "$WORKING_DIR" || exit 1
elif [ "$PLATFORM" = "linux" ]; then
  CGO_ENABLED=1 GOOS="linux" GOARCH="amd64" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/Proxyserver-Desktop-Linux-amd64-v${VERSION_NAME}"
  # TODO: Linux arm64?
#  CGO_ENABLED=1 GOOS="linux" GOARCH="arm64" CC=aarch64-linux-gnu-gcc go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "$OUTPUT_DIR/Proxyserver-Desktop-Linux-arm64-v${VERSION_NAME}"

  # Compressing output bundles
  # echo "Compressing output bundles"
  # WORKING_DIR=$(pwd)
  # cd "$OUTPUT_DIR" || exit 1
  # zip -r "Proxyserver-Linux-v${VERSION_NAME}.zip" "Proxyserver-Linux-v${VERSION_NAME}"
  # cd "$WORKING_DIR" || exit 1
fi

echo ""
echo ""
fcomplete
