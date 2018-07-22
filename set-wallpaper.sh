#!/bin/bash

# Steps:
# 1. Create a list of images available.
# 2. Check if old list needs to be updated.
# 3. If yes, update and add newer pictures.
# 4. Else, select one picture from the folder, and set as wallpaper.

# Run this script from the https://gitlab.com/nji/lnxpcs directory


# Progress bar courtesy https://stackoverflow.com/a/28044986
# ProgressBar is called with two arguments:
# ProgressBar $current_Index $max_Index
# where current_Index will dictate the current progress ratio
#       max_Index is the total value from which the ratio is calculated.
function ProgressBar {
    # Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1 Progress : [########################################] 100%
    printf "On File $(($1 + 1)); Progress : [${_fill// /#}${_empty// /-}] ${_progress}%%\r"
}

function create_build_dir {
    mkdir -p build
    cd build/

    local num_of_entries=$(wc -l <$1)
    
    # Iterator to keep track of file number
    local i=0 

    printf "Converting $num_of_entries images from original size to desktop size of 1366x768.\
    \nStop this program now if 1366x768 isn't the size you want, and change it as \
    needed.\n\n"
    # Read each line in file
    while read -r entry || [[ -n $line ]]; do
        ProgressBar ${i} ${num_of_entries}
        ../makemywall -s 1366 768 ../$entry
        i=$((i + 1))
    done <$1
}

function check_if_updated {
    git pull
    
    # Get the list of images which are listed in all folders in the
    # current directory except build/ , remove the entry for 
    # ./build from the resulting list, and store it to check against 
    # the older list.
    find ./ -type f -name '*.png' \
        -o -path ./build -prune \
        -not -wholename '*build' > temp-updated.txt
    
    # listofimages.txt contains the old list of images
    diff <(sort temp-updated.txt) <(sort listofimages.txt)
    
    # We check whether diff returned 0 - no diff in files, or 1 - there was a
    # change in files, or >1 - some error occurred.
    
    # $? returns the exit code of the last executed command ie. in our case
    # the diff command
    # https://stackoverflow.com/a/7248048
    case $? in
        0)
            printf "No New files since last run.\nRun git pull if you want to add newer photos.\n"
            rm temp-updated.txt
            ;;
        1)
            printf "Files updated since last run. Adding newer files.\n"
            # TODO: Need to add newer files by taking only the diff into account
            # For now - replace the entire file by the newer one and run the
            # makemywall script again.
            sort listofimages > listofimages.txt
            sort temp-updated.txt > temp-updated.txt
            # Add all the image locations in temp-updated.txt to listofimages.txt
            comm -13 listofimages.txt temp-updated.txt > updatedlistofimages.txt
            comm -13 listofimages.txt temp-updated.txt >>listofimages.txt
            # Pass only the new images list to create_build_dir to update 
            # and add new pictures which can be then be chosen randomly from.
            create_build_dir updatedlistofimages.txt
            rm temp-updated.txt updatedlistofimages.txt
            ;;
        *)
            # ie. this is the default case to match anything else
            printf "An error occured in comparing file lists.\nExiting.\n"
            exit 
            ;;
    esac
}

check_if_updated
bash -c 'pcmanfm -w "$(find $(pwd)/build -type f | shuf -n1)"'
