#!/bin/sh

WORK_DIR=$(pwd)

LINARO_DIR=/opt/linaro/gcc-linaro-arm-linux-gnueabi-2012.04-20120426_linux
LINARO_VER=4.7.1

TARGET_TRIPLE=arm-linux-gnueabi

LLVM_REPO=http://llvm.org/git/llvm.git
LLVM_DIR=$WORK_DIR/llvm

CLANG_REPO=http://llvm.org/git/clang.git
CLANG_DIR=$WORK_DIR/clang
CLANG_BUILD_DIR=$WORK_DIR/build-clang

LIBCXX_REPO=http://llvm.org/git/libcxx.git
LIBCXX_DIR=$WORK_DIR/libcxx
LIBCXX_BUILD_DIR=$WORK_DIR/build-libcxx

INSTALL_DIR=$WORK_DIR/install

function clean_install()
{
    echo Cleaning installation folder ...
    if [ -d $INSTALL_DIR ]; then
        rm -r $INSTALL_DIR
    fi
}

function clone_llvm()
{
    echo Cloning llvm ...
    git clone $LLVM_REPO $LLVM_DIR
    cd $LLVM_DIR
    git checkout release_39
}

function clone_clang()
{
    echo Cloning clang ...
    git clone $CLANG_REPO $CLANG_DIR
    cd $CLANG_DIR
    git checkout release_39
}

function clean_clang()
{
    echo Cleaning clang ...
    if [ -d $CLANG_BUILD_DIR ]; then
        rm -r $CLANG_BUILD_DIR
    fi
}

function config_clang()
{
    echo Configuring clang ...
    if [ ! -d $CLANG_BUILD_DIR ]; then
        mkdir $CLANG_BUILD_DIR
    fi
    cd $CLANG_BUILD_DIR

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=$CLANG_DIR \
        $LLVM_DIR
}

function build_clang()
{
    echo Building clang ...
    cd $CLANG_BUILD_DIR
    make -j9
}

function install_clang()
{
    echo Installing clang ...
    cd $CLANG_BUILD_DIR
    make install
}

function clone_libcxx()
{
    echo Cloning libcxx ...
    git clone $LIBCXX_REPO $LIBCXX_DIR
    cd $LIBCXX_DIR
    git checkout release_39
}

function clean_libcxx()
{
    echo Cleaning libcxx ...
    if [ -d $LIBCXX_BUILD_DIR ]; then
        rm -r $LIBCXX_BUILD_DIR
    fi
}

function config_libcxx()
{
    echo Configuring libcxx ...
    if [ ! -d $LIBCXX_BUILD_DIR ]; then
        mkdir $LIBCXX_BUILD_DIR
    fi
    cd $LIBCXX_BUILD_DIR

    LINARO=$LINARO_DIR
    TRIPLE=$TARGET_TRIPLE
    VER=$LINARO_VER

    SYSROOT_FLAG="--sysroot=$LINARO/$TRIPLE/libc"
    ARCH_FLAGS="-march=armv7-a -mcpu=cortex-a9 -mfloat-abi=soft"

    C_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/ "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/$TRIPLE/ "

    LINKER_FLAGS="-fuse-ld=$LINARO/bin/$TRIPLE-ld "
    LINKER_FLAGS+="-B $LINARO/lib/gcc/$TRIPLE/$VER/ "
    LINKER_FLAGS+="-L $LINARO/lib/gcc/$TRIPLE/$VER/ "
    LINKER_FLAGS+="-L $LINARO/$TRIPLE/lib/ "

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        -DCMAKE_C_COMPILER=$INSTALL_DIR/bin/clang \
        -DCMAKE_C_FLAGS="$C_FLAGS" \
        -DCMAKE_CXX_COMPILER=$INSTALL_DIR/bin/clang++ \
        -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="$LINKER_FLAGS" \
        -DCMAKE_SHARED_LINKER_FLAGS="$LINKER_FLAGS" \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_EXTERNAL_LIBCXX_SOURCE_DIR=$LIBCXX_DIR \
        -DLIBCXX_CXX_ABI=libstdc++ \
        -DLIBCXX_CXX_ABI_LIBRARY_PATH=$LINARO/$TRIPLE/lib/libstdc++.a \
        $LLVM_DIR
}

function build_libcxx()
{
    cd $LIBCXX_BUILD_DIR
    make -j9 cxx
}

function install_libcxx()
{
    cd $LIBCXX_BUILD_DIR
    make install-libcxx
}

for cmd in "$@"; do
    $cmd
done
