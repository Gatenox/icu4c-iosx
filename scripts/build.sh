#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
ICU_VER=maint/maint-70
################## SETUP END
DEVSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
SIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

ICU_VER_NAME=icu4c-${ICU_VER//\//-}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR="$BUILD_DIR/product"

if [ "$HOST_ARC" = "arm64" ]; then
	BUILD_ARC=arm
else
	BUILD_ARC=$HOST_ARC
fi

#explicit 70.1
pushd icu
git reset --hard a56dde820dc35665a66f2e9ee8ba58e75049b668
popd

ICU4C_FOLDER=icu/icu4c

################### BUILD FOR macOS Host
ICU_HOST_BUILD_FOLDER=$ICU_VER_NAME-build
if [ ! -f $ICU_HOST_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_HOST_BUILD_FOLDER ...
if [ -d $ICU_HOST_BUILD_FOLDER ]; then
    rm -rf $ICU_HOST_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_HOST_BUILD_FOLDER

echo "building icu (mac osx)..."
pushd $ICU_HOST_BUILD_FOLDER/source

./runConfigureICU MacOSX --enable-static --disable-shared prefix=$BUILD_DIR/$ICU_HOST_BUILD_FOLDER/install CXXFLAGS="--std=c++17"
make -j$THREAD_COUNT
make install
popd
touch $ICU_HOST_BUILD_FOLDER.success 
fi

################### BUILD FOR MAC Catalyst x86_64
ICU_CATALYST_BUILD_FOLDER=$ICU_VER_NAME-catalyst-build
if [ ! -f $ICU_CATALYST_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_CATALYST_BUILD_FOLDER ...
if [ -d $ICU_CATALYST_BUILD_FOLDER ]; then
    rm -rf $ICU_CATALYST_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_CATALYST_BUILD_FOLDER
echo "building icu (mac osx: Catalyst)..."
pushd $ICU_CATALYST_BUILD_FOLDER/source

COMMON_CFLAGS="-arch x86_64 -fembed-bitcode --target=$BUILD_ARC-apple-ios13-macabi -isysroot $MACSYSROOT -I$MACSYSROOT/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/System/iOSSupport/usr/include -iframework $MACSYSROOT/System/iOSSupport/System/Library/Frameworks"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$BUILD_DIR/$ICU_CATALYST_BUILD_FOLDER/install --host=$BUILD_ARC-apple-darwin --build=$BUILD_ARC-apple --with-cross-build=$BUILD_DIR/$ICU_HOST_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$MACSYSROOT/System/iOSSupport/usr/lib/ -isysroot $MACSYSROOT -Wl,-dead_strip -lstdc++"

make -j$THREAD_COUNT
make install
popd
touch $ICU_CATALYST_BUILD_FOLDER.success 
fi

################### BUILD FOR SIM x86_64
ICU_IOS_SIM_BUILD_FOLDER=$ICU_VER_NAME-ios.sim-build
if [ ! -f $ICU_IOS_SIM_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_IOS_SIM_BUILD_FOLDER ...
if [ -d $ICU_IOS_SIM_BUILD_FOLDER ]; then
    rm -rf $ICU_IOS_SIM_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_IOS_SIM_BUILD_FOLDER
echo "building icu (iOS: iPhoneSimulator)..."
pushd $ICU_IOS_SIM_BUILD_FOLDER/source

COMMON_CFLAGS="-arch x86_64 -fembed-bitcode -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -I$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/include/"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$BUILD_DIR/$ICU_IOS_SIM_BUILD_FOLDER/install --host=$BUILD_ARC-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_HOST_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/lib/ -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -Wl,-dead_strip -lstdc++"

make -j$THREAD_COUNT
make install
popd
touch $ICU_IOS_SIM_BUILD_FOLDER.success 
fi

################### BUILD FOR SIM ARM64
ICU_IOS_SIM_ARM_BUILD_FOLDER=$ICU_VER_NAME-ios.sim.arm64-build
if [ ! -f $ICU_IOS_SIM_ARM_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_IOS_SIM_ARM_BUILD_FOLDER ...
if [ -d $ICU_IOS_SIM_ARM_BUILD_FOLDER ]; then
    rm -rf $ICU_IOS_SIM_ARM_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_IOS_SIM_ARM_BUILD_FOLDER
echo "building icu (iOS: iPhoneSimulator ARM64)..."
pushd $ICU_IOS_SIM_ARM_BUILD_FOLDER/source

COMMON_CFLAGS="-arch arm64 -fembed-bitcode -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -I$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/include/"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$BUILD_DIR/$ICU_IOS_SIM_ARM_BUILD_FOLDER/install --host=$BUILD_ARC-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_HOST_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$SIMSYSROOT/SDKs/iPhoneSimulator.sdk/usr/lib/ -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk -Wl,-dead_strip -lstdc++"

make -j$THREAD_COUNT
make install
popd
touch $ICU_IOS_SIM_ARM_BUILD_FOLDER.success 
fi

################### BUILD FOR iOS
ICU_IOS_BUILD_FOLDER=$ICU_VER_NAME-ios.dev-build
if [ ! -f $ICU_IOS_BUILD_FOLDER.success ]; then
echo preparing build folder $ICU_IOS_BUILD_FOLDER ...
if [ -d $ICU_IOS_BUILD_FOLDER ]; then
    rm -rf $ICU_IOS_BUILD_FOLDER
fi
cp -r $ICU4C_FOLDER $ICU_IOS_BUILD_FOLDER
echo "building icu (iOS: iPhoneOS)..."
pushd $ICU_IOS_BUILD_FOLDER/source

COMMON_CFLAGS="-arch arm64 -fembed-bitcode -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -I$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/include/"
./configure --disable-tools --disable-extras --disable-tests --disable-samples --disable-dyload --enable-static --disable-shared prefix=$BUILD_DIR/$ICU_IOS_BUILD_FOLDER/install --host=arm-apple-darwin --with-cross-build=$BUILD_DIR/$ICU_HOST_BUILD_FOLDER/source CFLAGS="$COMMON_CFLAGS" CXXFLAGS="$COMMON_CFLAGS -c -stdlib=libc++ -Wall --std=c++17" LDFLAGS="-stdlib=libc++ -L$DEVSYSROOT/SDKs/iPhoneOS.sdk/usr/lib/ -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk -Wl,-dead_strip -lstdc++"
make -j$THREAD_COUNT
make install
popd
touch $ICU_IOS_BUILD_FOLDER.success 
fi

################### PACKAGE RESULTS

if [ -d $INSTALL_DIR ]; then
    rm -rf $INSTALL_DIR
fi
mkdir $INSTALL_DIR

mkdir $INSTALL_DIR/combined
pushd $INSTALL_DIR/combined

mkdir catalyst-x86_64-combined
libtool -static -o catalyst-x86_64-combined/icu4c.a \
    $BUILD_DIR/$ICU_CATALYST_BUILD_FOLDER/install/lib/libicudata.a \
    $BUILD_DIR/$ICU_CATALYST_BUILD_FOLDER/install/lib/libicui18n.a \
    $BUILD_DIR/$ICU_CATALYST_BUILD_FOLDER/install/lib/libicuio.a \
    $BUILD_DIR/$ICU_CATALYST_BUILD_FOLDER/install/lib/libicuuc.a

mkdir sim-x86_64-combined
libtool -static -o sim-x86_64-combined/icu4c.a \
    $BUILD_DIR/$ICU_IOS_SIM_BUILD_FOLDER/install/lib/libicudata.a \
    $BUILD_DIR/$ICU_IOS_SIM_BUILD_FOLDER/install/lib/libicui18n.a \
    $BUILD_DIR/$ICU_IOS_SIM_BUILD_FOLDER/install/lib/libicuio.a \
    $BUILD_DIR/$ICU_IOS_SIM_BUILD_FOLDER/install/lib/libicuuc.a

mkdir sim-arm64-combined
libtool -static -o sim-arm64-combined/icu4c.a \
    $BUILD_DIR/$ICU_IOS_SIM_ARM_BUILD_FOLDER/install/lib/libicudata.a \
    $BUILD_DIR/$ICU_IOS_SIM_ARM_BUILD_FOLDER/install/lib/libicui18n.a \
    $BUILD_DIR/$ICU_IOS_SIM_ARM_BUILD_FOLDER/install/lib/libicuio.a \
    $BUILD_DIR/$ICU_IOS_SIM_ARM_BUILD_FOLDER/install/lib/libicuuc.a

mkdir ios-arm64-combined
libtool -static -o ios-arm64-combined/icu4c.a \
    $BUILD_DIR/$ICU_IOS_BUILD_FOLDER/install/lib/libicudata.a \
    $BUILD_DIR/$ICU_IOS_BUILD_FOLDER/install/lib/libicui18n.a \
    $BUILD_DIR/$ICU_IOS_BUILD_FOLDER/install/lib/libicuio.a \
    $BUILD_DIR/$ICU_IOS_BUILD_FOLDER/install/lib/libicuuc.a

mkdir sim-arm64_x86_64-combined
xcrun lipo -create -output sim-arm64_x86_64-combined/icu4c.a \
    sim-x86_64-combined/icu4c.a \
    sim-arm64-combined/icu4c.a
    
popd

mkdir $INSTALL_DIR/frameworks
pushd $INSTALL_DIR/frameworks

xcodebuild -create-xcframework \
  -library $INSTALL_DIR/combined/catalyst-x86_64-combined/icu4c.a -headers $BUILD_DIR/$ICU_CATALYST_BUILD_FOLDER/install/include \
  -library $INSTALL_DIR/combined/ios-arm64-combined/icu4c.a -headers $BUILD_DIR/$ICU_IOS_BUILD_FOLDER/install/include \
  -library $INSTALL_DIR/combined/sim-arm64_x86_64-combined/icu4c.a -headers $BUILD_DIR/$ICU_IOS_SIM_ARM_BUILD_FOLDER/install/include \
  -output $INSTALL_DIR/frameworks/icu4c.xcframework

zip -r $INSTALL_DIR/icu4c-ios-${ICU_VER_TAG}.xcframework.zip icu4c.xcframework

popd