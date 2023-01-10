#!/bin/bash

cd $(dirname $0)

TARGET=$(cd roc_targets && ls *.roc | gum filter)
OPTIMIZE=$?
if gum confirm --default="No" "Optimized build?"
then
	ROCFLAG=--optimize
	FUZZFLAG=-O
fi

if gum confirm "Clear corpus? (This is recommended when switching target)"
then
	rm -rf fuzz/artifacts fuzz/corpus
fi

ROC_SANITIZERS="address,cargo-fuzz" roc build --no-link $ROCFLAG roc_targets/$TARGET

ar rcs roc_targets/libroc-fuzz.a roc_targets/libroc-fuzz.o

cargo fuzz run $FUZZFLAG roc-fuzz
