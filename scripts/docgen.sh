#!/bin/bash

# Save the current directory as the root directory
root_dir=$(pwd)

# Ensure the move-docs directory exists
mkdir -p "${root_dir}/move-docs"

# List of directories to exclude from processing
exclude_dirs=("governance")

# Convert the list of excluded directories to a lookup-ready string pattern
exclude_pattern=$(IFS="|"; echo "${exclude_dirs[*]}")

# Loop through each sub-directory in the /packages directory
for dir in "${root_dir}/packages"/*; do
    dir_name=$(basename "$dir")

    # Check if the current directory is in the list of excluded directories
    if [[ $exclude_pattern =~ (^| )$dir_name($| ) ]]; then
        echo "Skipping excluded directory: $dir"
        continue
    fi

    echo "$dir"
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"

        # Change to the sub-directory
        cd "$dir" || { echo "Failed to change directory to $dir"; continue; }

        # Run the sui move build --doc command
        if ! sui move build --doc; then
            echo "Failed to build documentation in $dir"
            cd "$root_dir"
            continue
        fi

        # Define the path where docs are expected to be
        doc_path="build/${dir##*/}/docs"

        # Check if the documentation directory exists
        if [ -d "$doc_path" ]; then
            # Move all .md files from the specific docs directory to the /move-docs directory at the root
            find "$doc_path" -maxdepth 1 -type f -name '*.md' -exec mv {} "${root_dir}/move-docs/" \;
        else
            echo "Documentation directory does not exist: $doc_path"
        fi

        # Go back to the root directory
        cd "$root_dir"
    fi
done

echo "Documentation processing complete."
