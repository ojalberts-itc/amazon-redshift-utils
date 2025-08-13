#!/usr/bin/env bash
set -e

# Sync local master with upstream/master and push to origin/master

git fetch upstream
git checkout master
git merge upstream/master
git push origin master
