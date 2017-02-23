#!/bin/sh

WORK_DIR=$(pwd)

LINARO_DIR=/opt/linaro/gcc-linaro-arm-linux-gnueabi-2012.04-20120426_linux
LINARO_VER=4.7.1

TARGET_TRIPLE=arm-linux-gnueabi

LLVM_REPO=http://llvm.org/git/llvm.git
LLVM_DIR=$WORK_DIR/llvm

CLANG_REPO=http://llvm.org/git/clang.git
CLANG_DIR=$WORK_DIR/clang
LLD_REPO=http://llvm.org/git/lld.git
LLD_DIR=$WORK_DIR/lld
TOOLS_BUILD_DIR=$WORK_DIR/build-tools

COMPILER_RT_REPO=http://llvm.org/git/compiler-rt.git
COMPILER_RT_DIR=$WORK_DIR/compiler-rt
COMPILER_RT_BUILD_DIR=$WORK_DIR/build-compiler-rt

LIBUNWIND_REPO=http://llvm.org/git/libunwind.git
LIBUNWIND_DIR=$WORK_DIR/libunwind
LIBUNWIND_BUILD_DIR=$WORK_DIR/build-libunwind

LIBCXXABI_REPO=http://llvm.org/git/libcxxabi.git
LIBCXXABI_DIR=$WORK_DIR/libcxxabi
LIBCXXABI_BUILD_DIR=$WORK_DIR/build-libcxxabi

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

function clean_tools()
{
    echo Cleaning tools ...
    if [ -d $TOOLS_BUILD_DIR ]; then
        rm -r $TOOLS_BUILD_DIR
    fi
}

function config_tools()
{
    echo Configuring tools ...
    if [ ! -d $TOOLS_BUILD_DIR ]; then
        mkdir $TOOLS_BUILD_DIR
    fi
    cd $TOOLS_BUILD_DIR

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=$CLANG_DIR \
        -DLLVM_EXTERNAL_LLD_SOURCE_DIR=$LLD_DIR \
        $LLVM_DIR
}

function build_tools()
{
    echo Building tools ...
    cd $TOOLS_BUILD_DIR
    make -j9
}

function install_tools()
{
    echo Installing tools ...
    cd $TOOLS_BUILD_DIR
    make install/strip
}

function clone_lld()
{
    echo Cloning lld ...
    git clone $LLD_REPO $LLD_DIR
    cd $LLD_DIR
    git checkout release_39
}

function clone_compiler_rt()
{
    echo Cloning compiler-rt ...
    git clone $COMPILER_RT_REPO $COMPILER_RT_DIR
    cd $COMPILER_RT_DIR
    git checkout release_39
}

function clean_compiler_rt()
{
    echo Cleaning compiler-rt ...
    if [ -d $COMPILER_RT_BUILD_DIR ]; then
        rm -r $COMPILER_RT_BUILD_DIR
    fi
}

function config_compiler_rt()
{
    echo Configuring compiler-rt ...
    if [ ! -d $COMPILER_RT_BUILD_DIR ]; then
        mkdir $COMPILER_RT_BUILD_DIR
    fi
    cd $COMPILER_RT_BUILD_DIR

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
        -DCMAKE_CROSSCOMPILING=TRUE \
        -DCMAKE_C_COMPILER=$INSTALL_DIR/bin/clang \
        -DCMAKE_C_FLAGS="$C_FLAGS" \
        -DCMAKE_CXX_COMPILER=$INSTALL_DIR/bin/clang++ \
        -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="$LINKER_FLAGS" \
        -DCMAKE_SHARED_LINKER_FLAGS="$LINKER_FLAGS" \
        -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE \
        -DLLVM_TARGET_ARCH=ARM \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_EXTERNAL_COMPILER_RT_SOURCE_DIR=$COMPILER_RT_DIR \
        $LLVM_DIR
}

function clone_libunwind()
{
    echo Cloning libunwind ...
    git clone $LIBUNWIND_REPO $LIBUNWIND_DIR
    cd $LIBUNWIND_DIR
    git checkout release_39
}

function clean_libunwind()
{
    echo Cleaning libunwind ...
    if [ -d $LIBUNWIND_BUILD_DIR ]; then
        rm -r $LIBUNWIND_BUILD_DIR
    fi
}

function config_libunwind()
{
    echo Configuring libunwind ...
    if [ ! -d $LIBUNWIND_BUILD_DIR ]; then
        mkdir $LIBUNWIND_BUILD_DIR
    fi
    cd $LIBUNWIND_BUILD_DIR

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
        -DLLVM_EXTERNAL_LIBUNWIND_SOURCE_DIR=$LIBUNWIND_DIR \
        -DLIBUNWIND_ENABLE_SHARED=OFF \
        $LLVM_DIR
}

function build_libunwind()
{
    echo Building libunwind ...
    cd $LIBUNWIND_BUILD_DIR
    make -j9 unwind
}

function install_libunwind()
{
    echo Installing libunwind ...
    cd $LIBUNWIND_BUILD_DIR/projects/libunwind
    make install
}

function clone_libcxxabi()
{
    echo Cloning libcxxabi ...
    git clone $LIBCXXABI_REPO $LIBCXXABI_DIR
    cd $LIBCXXABI_DIR
    git checkout release_39
}

function clean_libcxxabi()
{
    echo Cleaning libcxxabi ...
    if [ -d $LIBCXXABI_BUILD_DIR ]; then
        rm -r $LIBCXXABI_BUILD_DIR
    fi
}

function config_libcxxabi()
{
    echo Configuring libcxxabi ...
    if [ ! -d $LIBCXXABI_BUILD_DIR ]; then
        mkdir $LIBCXXABI_BUILD_DIR
    fi
    cd $LIBCXXABI_BUILD_DIR

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
        -DLLVM_EXTERNAL_LIBCXXABI_SOURCE_DIR=$LIBCXXABI_DIR \
        -DLIBCXXABI_LIBCXX_PATH=$LIBCXX_DIR \
        -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
        -DLIBCXXABI_LIBUNWIND_PATH=$LIBUNWIND_DIR \
        -DLIBCXXABI_ENABLE_SHARED=OFF \
        $LLVM_DIR
}

function build_libcxxabi()
{
    echo Building libcxxabi ...
    cd $LIBCXXABI_BUILD_DIR
    make -j9 cxxabi
}

function install_libcxxabi()
{
    echo Installing libcxxabi ...
    cd $LIBCXXABI_BUILD_DIR
    make install-libcxxabi
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
    echo Building libcxx ...
    cd $LIBCXX_BUILD_DIR
    make -j9 cxx
}

function install_libcxx()
{
    echo Installing libcxx ...
    cd $LIBCXX_BUILD_DIR
    make install-libcxx
}

for cmd in "$@"; do
    $cmd
done
