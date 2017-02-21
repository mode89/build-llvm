#!/bin/sh

WORK_DIR=$(pwd)

LLVM_REPO=http://llvm.org/git/llvm.git
LLVM_DIR=.llvm

function clone_llvm()
{
    git clone $LLVM_REPO $LLVM_DIR
    cd $LLVM_DIR
    git checkout release_39
    cd $WORK_DIR
}

$1
