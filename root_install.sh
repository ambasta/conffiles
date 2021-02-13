#!/bin/bash
for file in $(find etc usr -type f)
do
    filepath="/$file"
    filedir=$(dirname $filepath)

    if !( [ -d "$filedir" ] )
    then
        mkdir -p $filedir
    fi

    if [ -f "$filepath" ] || [ -L "$filepath" ]
    then
        rm $filepath
    fi
    ln -s $(pwd)/${file} $filepath
done
