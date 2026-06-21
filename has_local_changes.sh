#!/usr/bin/env bash

git update-index -q --refresh

if ! git diff-index --quiet HEAD --; then
    exit 0
fi

if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    exit 0
fi

exit 1