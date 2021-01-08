#!/bin/bash
for file in $(find homedir -type f)
do
    filepath=$HOME/${file#homedir/}
    filedir=$(dirname $filepath)

    if ! ( [ -d "$filedir" ] && [ $filedir != $HOME ] )
    then
        mkdir -p $filedir
    fi

    if [ -f "$filepath" ] || [ -L "$filepath" ]
    then
        rm "$filepath"
    fi
    ln -s $(pwd)/${file} $filepath
done
