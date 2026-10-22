#!/bin/sh

# This script is used to build the Books app and create a tipa file with Xcode.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Build using Xcode
xcodebuild build archive \
    -scheme Books \
    -project Books.xcodeproj \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -archivePath Books \
    CODE_SIGNING_ALLOWED=NO # | xcpretty

chmod 0644 Resources/Info.plist
chmod 0644 supports/Sandbox-Info.plist
cp supports/entitlements.plist Books.xcarchive/Products
cd Books.xcarchive/Products/Applications
codesign --remove-signature Books.app

cd -
cd Books.xcarchive/Products
mv Applications Payload

# bew install ldid # 伪装签名
ldid -Sentitlements.plist Payload/Books.app
chmod 0644 Payload/Books.app/Info.plist
zip -qr Books.tipa Payload
cd -
mkdir -p packages
mv Books.xcarchive/Products/Books.tipa packages/Books_$VERSION.tipa
mv Books.xcarchive packages/Books.xcarchive
