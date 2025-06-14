#!/bin/sh

# This script is used to build the DZ app and create a tipa file with Xcode.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Build using Xcode
xcodebuild build archive \
    -scheme DZ \
    -project DZ.xcodeproj \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -archivePath DZ \
    CODE_SIGNING_ALLOWED=NO # | xcpretty

chmod 0644 Resources/Info.plist
chmod 0644 supports/Sandbox-Info.plist
cp supports/entitlements.plist DZ.xcarchive/Products
cd DZ.xcarchive/Products/Applications
codesign --remove-signature DZ.app

cd -
cd DZ.xcarchive/Products
mv Applications Payload

# bew install ldid # 伪装签名
ldid -Sentitlements.plist Payload/DZ.app
chmod 0644 Payload/DZ.app/Info.plist
zip -qr DZ.tipa Payload
cd -
mkdir -p packages
mv DZ.xcarchive/Products/DZ.tipa packages/DZ_$VERSION.tipa
