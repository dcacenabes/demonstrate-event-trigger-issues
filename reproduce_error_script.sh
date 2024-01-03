#!/bin/bash

# Check if the number of iterations is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_iterations>"
  exit 1
fi

# Number of iterations
iterations=$1

# GitHub repository name
repository_name="dcacenabes/demonstrate-event-trigger-issues"

git branch | grep -v "main" | xargs git branch -D
gh pr list -s open | awk '{print $1}' | xargs -I{} gh pr close {} -d

# Loop through the specified number of iterations
for ((i=1; i<=iterations; i++)); do
  git checkout main
  branch_name="reproduce-github-trigger-error-$i"
  label_name="label-$i"
  gh api repos/"$repository_name"/labels/$label_name -X DELETE --silent

  # Execute the given command to create a branch
  git checkout -b "$branch_name" && git commit --allow-empty -m "Empty-Commit" && git push

  # Print a separator between iterations
  echo "Iteration $i completed"

  # Execute GitHub API calls using gh api
  gh api repos/"$repository_name"/labels \
    -X POST \
    -F name="$label_name" \
    -F color=FFAABB \
    -F description="Label for iteration $i" \
    --silent

  gh pr create -d -f -l $label_name
  gh api repos/"$repository_name"/pulls \
    -X POST \
    -F base=main \
    -F head="$branch_name" \
    -F title="Draft PR for iteration $i" \
    -F draft=true \
    -F labels="$label_name" \
    --silent

  # Print a message indicating GitHub API calls execution
  echo "GitHub API calls for iteration $i executed"
done

git checkout main
