#!/bin/bash

set -e

pushd $(dirname $0)

source set_eidmw_version.sh
source set_eidmw_username.sh

EIDVIEWER_DMG="eID Viewer-$REL_VERSION.dmg"

rm -rf release-viewer
mkdir -p release-viewer
rm -f tmp-eidviewer.dmg
rm -f "eID Viewer-$REL_VERSION.dmg"

pushd "../../"
xcodebuild -project "beidmw.xcodeproj" -scheme "eID Viewer" -configuration Release clean archive
popd


hdiutil create -srcdir release-viewer -volname "eID Viewer" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "tmp-eidviewer.dmg"
DEVNAME=$(hdiutil attach -readwrite -noverify -noautoopen "tmp-eidviewer.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}')
mkdir -p "/Volumes/eID Viewer/.background/"
cp -a ../../installers/eid-viewer/mac/bg.png "/Volumes/eID Viewer/.background/"
cp -a "../../export/eID Viewer.app" "/Volumes/eID Viewer/"
ln -s /Applications "/Volumes/eID Viewer/ "
/usr/bin/osascript "../../installers/eid-viewer/mac/setlayout.applescript" "eID Viewer" || true
sleep 4
hdiutil detach $DEVNAME
hdiutil convert tmp-eidviewer.dmg -format UDBZ -o "$EIDVIEWER_DMG"


#notarize the eIDViewer installer
/usr/bin/xcrun altool --notarize-app --primary-bundle-id "be.eid.ViewerInstaller.dmg" --username "$AC_USERNAME" --password "@keychain:altool" --file "$EIDVIEWER_DMG"
xcrun altool --notarization-history 0 -u "$AC_USERNAME" -p "@keychain:altool"

sleep 20

#staple the notarization package to the DMG.
/usr/bin/xcrun stapler staple -v "$EIDVIEWER_DMG"

popd