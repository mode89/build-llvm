#!/bin/sh

WORK_DIR=$(pwd)
INSTALL_DIR=$WORK_DIR/install

LINARO_DIR=/opt/linaro/gcc-linaro-arm-linux-gnueabi-2012.04-20120426_linux
LINARO_VER=4.7.1
JOBS="-j9"

TARGET_TRIPLE=arm-linux-gnueabi
ARCH_FLAGS="-march=armv7-a -mcpu=cortex-a9 -mfloat-abi=softfp"
SYSROOT_FLAG="--sysroot=$LINARO_DIR/$TARGET_TRIPLE/libc"
FUSE_LD_LLD_FLAG="-fuse-ld=$INSTALL_DIR/bin/ld.lld"

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

LIBOMP_REPO=http://llvm.org/git/openmp.git
LIBOMP_DIR=$WORK_DIR/libomp
LIBOMP_BUILD_DIR=$WORK_DIR/build-libomp

function exit_on_error()
{
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

function clean_install()
{
    echo Cleaning installation folder ...
    if [ -d $INSTALL_DIR ]; then
        rm -r $INSTALL_DIR
    fi

    exit_on_error
}

function clone_llvm()
{
    echo Cloning llvm ...
    git clone $LLVM_REPO $LLVM_DIR
    exit_on_error
    cd $LLVM_DIR
    git checkout release_40
    exit_on_error
}

function clone_clang()
{
    echo Cloning clang ...
    git clone $CLANG_REPO $CLANG_DIR
    exit_on_error
    cd $CLANG_DIR
    git checkout release_40
    exit_on_error
}

function clean_tools()
{
    echo Cleaning tools ...
    if [ -d $TOOLS_BUILD_DIR ]; then
        rm -r $TOOLS_BUILD_DIR
    fi
    exit_on_error
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
        -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=$CLANG_DIR \
        -DLLVM_EXTERNAL_LLD_SOURCE_DIR=$LLD_DIR \
        $LLVM_DIR
    exit_on_error
}

function build_tools()
{
    echo Building tools ...
    cd $TOOLS_BUILD_DIR
    make $JOBS
    exit_on_error
}

function install_tools()
{
    echo Installing tools ...
    cd $TOOLS_BUILD_DIR
    make install/strip
    exit_on_error
}

function clone_lld()
{
    echo Cloning lld ...
    git clone $LLD_REPO $LLD_DIR
    exit_on_error
    cd $LLD_DIR
    git checkout release_40
    exit_on_error
}

function clone_compiler_rt()
{
    echo Cloning compiler-rt ...
    git clone $COMPILER_RT_REPO $COMPILER_RT_DIR
    exit_on_error
    cd $COMPILER_RT_DIR
    git checkout release_40
    exit_on_error
}

function clean_compiler_rt()
{
    echo Cleaning compiler-rt ...
    if [ -d $COMPILER_RT_BUILD_DIR ]; then
        rm -r $COMPILER_RT_BUILD_DIR
    fi
    exit_on_error
}

function patch_compiler_rt()
{
    echo Patching compiler-rt ...
    cd $COMPILER_RT_DIR
    git apply "$WORK_DIR/compiler-rt-cmake-dummy-properties.patch"
    exit_on_error
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

    C_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/ "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/$TRIPLE/ "

    LINKER_FLAGS="$FUSE_LD_LLD_FLAG "
    LINKER_FLAGS+="-B $LINARO/lib/gcc/$TRIPLE/$VER/ "
    LINKER_FLAGS+="-L $LINARO/lib/gcc/$TRIPLE/$VER/ "
    LINKER_FLAGS+="-L $LINARO/$TRIPLE/lib/ "
    LINKER_FLAGS+="-lpthread -lrt -ldl "

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
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_TRIPLE \
        -DLLVM_TARGET_ARCH=ARM \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_EXTERNAL_COMPILER_RT_SOURCE_DIR=$COMPILER_RT_DIR \
        $LLVM_DIR
    exit_on_error
}

function build_compiler_rt()
{
    echo Building compiler-rt ...
    cd $COMPILER_RT_BUILD_DIR
    make $JOBS compiler-rt
    exit_on_error
}

function install_compiler_rt()
{
    echo Installing compiler-rt ...
    cd $COMPILER_RT_BUILD_DIR/projects/compiler-rt
    make install
    exit_on_error
}

function clone_libunwind()
{
    echo Cloning libunwind ...
    git clone $LIBUNWIND_REPO $LIBUNWIND_DIR
    exit_on_error
    cd $LIBUNWIND_DIR
    git checkout release_40
    exit_on_error
}

function clean_libunwind()
{
    echo Cleaning libunwind ...
    if [ -d $LIBUNWIND_BUILD_DIR ]; then
        rm -r $LIBUNWIND_BUILD_DIR
    fi
    exit_on_error
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

    C_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/ "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/$TRIPLE/ "

    LINKER_FLAGS="$FUSE_LD_LLD_FLAG "
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
    exit_on_error
}

function build_libunwind()
{
    echo Building libunwind ...
    cd $LIBUNWIND_BUILD_DIR
    make $JOBS unwind
    exit_on_error
}

function install_libunwind()
{
    echo Installing libunwind ...
    cd $LIBUNWIND_BUILD_DIR/projects/libunwind
    make install
    exit_on_error
}

function clone_libcxxabi()
{
    echo Cloning libcxxabi ...
    git clone $LIBCXXABI_REPO $LIBCXXABI_DIR
    exit_on_error
    cd $LIBCXXABI_DIR
    git checkout release_40
    exit_on_error
}

function clean_libcxxabi()
{
    echo Cleaning libcxxabi ...
    if [ -d $LIBCXXABI_BUILD_DIR ]; then
        rm -r $LIBCXXABI_BUILD_DIR
    fi
    exit_on_error
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

    C_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/ "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/$TRIPLE/ "

    LINKER_FLAGS="$FUSE_LD_LLD_FLAG "
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
    exit_on_error
}

function build_libcxxabi()
{
    echo Building libcxxabi ...
    cd $LIBCXXABI_BUILD_DIR
    make $JOBS cxxabi
    exit_on_error
}

function install_libcxxabi()
{
    echo Installing libcxxabi ...
    cd $LIBCXXABI_BUILD_DIR
    make install-libcxxabi
    exit_on_error
}

function clone_libcxx()
{
    echo Cloning libcxx ...
    git clone $LIBCXX_REPO $LIBCXX_DIR
    exit_on_error
    cd $LIBCXX_DIR
    git checkout release_40
    exit_on_error
}

function clean_libcxx()
{
    echo Cleaning libcxx ...
    if [ -d $LIBCXX_BUILD_DIR ]; then
        rm -r $LIBCXX_BUILD_DIR
    fi
    exit_on_error
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

    C_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS="$SYSROOT_FLAG $ARCH_FLAGS "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/ "
    CXX_FLAGS+="-I $LINARO/$TRIPLE/include/c++/$VER/$TRIPLE/ "

    LINKER_FLAGS="$FUSE_LD_LLD_FLAG "
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
        -DLIBCXX_ENABLE_SHARED=ON \
        -DLIBCXX_CXX_ABI=libcxxabi \
        -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$LIBCXXABI_DIR/include \
        -DLIBCXX_CXX_ABI_LIBRARY_PATH=$LIBCXXABI_BUILD_DIR/lib \
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
        -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF \
        $LLVM_DIR
    exit_on_error
}

function build_libcxx()
{
    echo Building libcxx ...
    cd $LIBCXX_BUILD_DIR
    make $JOBS cxx
    exit_on_error
}

function install_libcxx()
{
    echo Installing libcxx ...
    cd $LIBCXX_BUILD_DIR/projects/libcxx
    make install
    exit_on_error
}

function clone_libomp()
{
    echo Cloning libomp ...
    git clone $LIBOMP_REPO $LIBOMP_DIR
    exit_on_error
    cd $LIBOMP_DIR
    git checkout release_40
    exit_on_error
}

function clean_libomp()
{
    echo Cleaning libomp ...
    if [ -d $LIBOMP_BUILD_DIR ]; then
        rm -r $LIBOMP_BUILD_DIR
    fi
    exit_on_error
}

function config_libomp()
{
    echo Configuring libomp ...
    if [ ! -d $LIBOMP_BUILD_DIR ]; then
        mkdir $LIBOMP_BUILD_DIR
    fi
    cd $LIBOMP_BUILD_DIR

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        -DCMAKE_C_COMPILER=$LINARO_DIR/bin/$TARGET_TRIPLE-gcc \
        -DCMAKE_CXX_COMPILER=$LINARO_DIR/bin/$TARGET_TRIPLE-g++ \
        -DLIBOMP_ARCH=arm \
        -DLIBOMP_LIB_TYPE=normal \
        -DLIBOMP_ENABLE_SHARED=OFF \
        $LIBOMP_DIR/runtime
    exit_on_error
}

function build_libomp()
{
    echo Building libomp ...
    cd $LIBOMP_BUILD_DIR
    make $JOBS
    exit_on_error
}

function install_libomp()
{
    echo Installing libomp ...
    cd $LIBOMP_BUILD_DIR
    make install/strip
    exit_on_error
}

function all()
{
    clone_llvm
    clone_clang
    clone_lld
    clone_compiler_rt
    clone_libunwind
    clone_libcxxabi
    clone_libcxx
    clone_libomp

    config_tools
    build_tools
    install_tools

    patch_compiler_rt
    config_compiler_rt
    build_compiler_rt
    install_compiler_rt

    config_libunwind
    build_libunwind
    install_libunwind

    config_libcxxabi
    build_libcxxabi
    install_libcxxabi

    config_libcxx
    build_libcxx
    install_libcxx

    config_libomp
    build_libomp
    install_libomp
}

for cmd in "$@"; do
    $cmd
done
