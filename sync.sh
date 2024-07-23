#!/bin/bash

# Overview on the script:
# 0. Set variables and functions
# 1. COMPARE source- and compare-structure for differences
# 2. COPY NEW folders and files from source to webdrive, if existing
# 3. REMOVE files and folders from webdrive, if necessary


# Variables
SOURCE_DIR="/mnt/source"
COMPARE_DIR="/mnt/compare"
WEBDRIVE_DIR="/mnt/webdrive"
#DIFFERENCES="/tmp/differences-report.txt"
FOLDER_CREATION_LIST="/tmp/folder-creation-list.txt"
FOLDER_DELETATION_LIST="/tmp/folder-deletation-list.txt"
COPY_LIST="/tmp/copy-list.txt"
DELETE_LIST="/tmp/delete-list.txt"


# Build the differences-report from "$SOURCE_DIR" and "$COMPARE_DIR"
# rsync -avun --delete --iconv=iso-8859-1,utf-8 \
#     "$SOURCE_DIR/" "$COMPARE_DIR/" | perl -ne 'print if /.*\.pdf$/' > "$DIFFERENCES"
# rsync -avn --iconv=iso-8859-1,utf-8\
#      --files-from="$DIFFERENCES" "$SOURCE_DIR/" "$WEBDRIVE_DIR/"
# exit



function find_different_folders () {
    # Compares each folder in path $1 to folders in path $2 and write different to result-list $3
    # $1=folder to search through
    # $2=folder to campare with
    # $3=result-list (only differents)
    # example: find_different_folders $SOURCE_DIR $COMPARE_DIR $FOLDER_CREATION_LIST
    find "$1" -type d | \
    while read -r src_dir; do
        dst_dir="${2}${src_dir#$1}"

        if [[ ! -f $3 ]]; then touch $3; fi

        if [ ! -d "$dst_dir" ]; then 
            echo "${src_dir/$1}" | cut -c2- >> $3
        fi
    done
}

function find_differences_in_folders () {
    # Compares each file in path $1 to files in path $2 and write different to result-list $3
    # the compare logic can be defined in $4: newer/older/identical
    # $1=folder to search through
    # $2=folder to campare with
    # $3=result-list (only differents)
    # $4=compare-file is allowed to be: newer/older/identical
    # example: find_differences_in_folders $SOURCE_DIR $COMPARE_DIR $COPY_LIST newer
    find "$1" -type f | \
    while read -r src_file; do
        dst_file="${2}${src_file#$1}"

        src_size=$(stat -c%s "$src_file")
        src_mtime=$(stat -c%Y "$src_file")

        if [ -f "$dst_file" ]; then
            dst_size=$(stat -c%s "$dst_file")
            dst_mtime=$(stat -c%Y "$dst_file")
        fi

        if [[ ! -f $3 ]]; then touch $3; fi

        if [[ $4 == "newer" ]]; then
            if (( $src_size != $dst_size )) || (( $src_mtime > $dst_mtime )); then
                echo "${src_file/$1}" | cut -c2- >> $3; fi
        elif [[ $4 == "older" ]]; then
            if (( $src_size != $dst_size )) || (( $src_mtime < $dst_mtime )); then
                echo "${src_file/$1}" | cut -c2- >> $3; fi
        else
            if (( $src_size != $dst_size )) || (( $src_mtime != $dst_mtime )); then
                echo "${src_file/$1}" | cut -c2- >> $3; fi
        fi
    done
}


# determine folders to be created, and create them in webdrive if necessary
find_different_folders $SOURCE_DIR $COMPARE_DIR $FOLDER_CREATION_LIST

if (( $(stat -c%s "$FOLDER_CREATION_LIST") == 0 )); then echo "no folder to create"; fi

IFS=$'\n'
for FOLDER in $(cat $FOLDER_CREATION_LIST); do
    mkdir "$WEBDRIVE_DIR/$FOLDER" --verbose
done


# determine files to be copied, and copy them to webdrive if necessary
find_differences_in_folders $SOURCE_DIR $COMPARE_DIR $COPY_LIST newer

if (( $(stat -c%s "$COPY_LIST") == 0 )); then echo "no file to copy"; fi

for FILE in $(cat $COPY_LIST); do
    cp "$SOURCE_DIR/$FILE" "$WEBDRIVE_DIR/$FILE" --verbose
done


# determine files to be deleted, and delete them in webdrive if necessary
find_differences_in_folders $COMPARE_DIR $SOURCE_DIR $DELETE_LIST older

if (( $(stat -c%s "$DELETE_LIST") == 0 )); then echo "no file to remove"; fi

for FILE in $(cat $DELETE_LIST); do
    if [[ ! $(cat $COPY_LIST) =~ $FILE ]]; then
        rm "$WEBDRIVE_DIR/$FILE" --verbose
    fi
done


# determine folder to be deleted, and delete them in webdrive if necessary
find_different_folders $COMPARE_DIR $SOURCE_DIR $FOLDER_DELETATION_LIST

if (( $(stat -c%s "$FOLDER_DELETATION_LIST") == 0 )); then echo "no folder to remove"; fi

IFS=$'\n'
for FOLDER in $(cat $FOLDER_DELETATION_LIST); do
    if [[ ! $(cat $FOLDER_CREATION_LIST) =~ $FOLDER ]]; then
        rm -d "$WEBDRIVE_DIR/$FOLDER" --verbose
    fi
done


# cleanup
rm $FOLDER_CREATION_LIST
rm $FOLDER_DELETATION_LIST
rm $COPY_LIST
rm $DELETE_LIST
