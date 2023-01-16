#!/bin/bash

cd $(dirname $0)

TARGETS=$(cd roc_targets && ls *.roc | gum choose --no-limit)
TIMEOUT=$(gum input --placeholder="Execution time per target (seconds)")

if gum confirm --default="No" "Optimized build?"
then
	ROCFLAG=--optimize
	FUZZFLAG=-O
fi

# Make sure this exits if anything fails.
set -e

for TARGET in $TARGETS
do
	echo -e "\n\nFuzzing $TARGET\n"

	rm -rf fuzz/artifacts fuzz/corpus

	ROC_SANITIZERS="address,cargo-fuzz" roc build --no-link $ROCFLAG roc_targets/$TARGET

	ar rcs roc_targets/libroc-fuzz.a roc_targets/libroc-fuzz.o

	cargo fuzz run $FUZZFLAG roc-fuzz -- -max_total_time=$TIMEOUT
done
