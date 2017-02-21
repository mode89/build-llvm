#!/bin/sh

WORK_DIR=$(pwd)

LLVM_REPO=http://llvm.org/git/llvm.git
LLVM_DIR=$WORK_DIR/llvm

CLANG_REPO=http://llvm.org/git/clang.git
CLANG_DIR=$WORK_DIR/clang
CLANG_BUILD_DIR=$WORK_DIR/build-clang

LIBCXX_REPO=http://llvm.org/git/libcxx.git
LIBCXX_DIR=$WORK_DIR/libcxx
LIBCXX_BUILD_DIR=$WORK_DIR/build-libcxx

INSTALL_DIR=$WORK_DIR/install

function clone_llvm()
{
    git clone $LLVM_REPO $LLVM_DIR
    cd $LLVM_DIR
    git checkout release_39
}

function clone_clang()
{
    git clone $CLANG_REPO $CLANG_DIR
    cd $CLANG_DIR
    git checkout release_39
}

function clean_clang()
{
    if [ -d $CLANG_BUILD_DIR ]; then
        rm -r $CLANG_BUILD_DIR
    fi
}

function config_clang()
{
    if [ ! -d $CLANG_BUILD_DIR ]; then
        mkdir $CLANG_BUILD_DIR
    fi
    cd $CLANG_BUILD_DIR

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_TARGETS_TO_BUILD=ARM \
        -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=$CLANG_DIR \
        $LLVM_DIR
}

function build_clang()
{
    cd $CLANG_BUILD_DIR
    make -j9
}

function install_clang()
{
    cd $CLANG_BUILD_DIR
    make install
}

function clone_libcxx()
{
    git clone $LIBCXX_REPO $LIBCXX_DIR
    cd $LIBCXX_DIR
    git checkout release_39
}

for cmd in "$@"; do
    $cmd
done
