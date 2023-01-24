#!/bin/bash

cd $(dirname $0)

TARGETS=$(cd roc_targets && ls *.roc | gum choose --no-limit)
TIMEOUT=$(gum input --placeholder="Execution time per target (seconds)")

if gum confirm --default="No" "Optimized build?"
then
	ROCFLAG=--optimize
	FUZZFLAG=-O
fi

FAILURES=()
for TARGET in $TARGETS
do
	echo -e "\n\nFuzzing $TARGET\n"

	rm -rf fuzz/artifacts fuzz/corpus

	ROC_SANITIZERS="address,cargo-fuzz" roc build --no-link $ROCFLAG roc_targets/$TARGET
	if [ $? -ne 0 ]; then
		FAILURES+=( $TARGET )
		continue
	fi

	ar rcs roc_targets/libroc-fuzz.a roc_targets/libroc-fuzz.o
	if [ $? -ne 0 ]; then
		FAILURES+=( $TARGET )
		continue
	fi

	cargo fuzz run $FUZZFLAG roc-fuzz -- -max_total_time=$TIMEOUT
	if [ $? -ne 0 ]; then
		FAILURES+=( $TARGET )
		continue
	fi
done

echo -e "\n\n==================================="
echo        "            Failures               "
echo -e     "===================================\n"
for FAILURE in ${FAILURES[@]}
do
	echo -e "$FAILURE"
done
