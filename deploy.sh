#!/bin/sh
git fetch --tags --force --prune-tags
git tag -d latest
git tag "$@" # intentional choice; if no parameters are given, just show the tags
_latest=$(git tag | sort -rV | head -n1)
git tag latest -m 'latest release' "$_latest"^{}
git push --tags --force
