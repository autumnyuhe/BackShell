#!/bin/bash

# clean remote branches history
git remote prune origin

current_local_branch=$(git branch | awk '/\*/ { print $2; }')
all_remote_branches=$(git branch --remotes | sed 's/origin\///g' | sed 's/HEAD -> master//g')
current_dir=$(pwd)
repo_dir=$(git rev-parse --show-toplevel)

cd $repo_dir

for remote_branch in ${all_remote_branches[*]}; do
    git checkout $remote_branch
    git pull
done

git checkout $current_local_branch
cd $current_dir