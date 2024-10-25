#!/usr/bin/env bash

. config.sh
./gen_bin_vocabulary.sh
./build_thirdparty.sh "$@"
