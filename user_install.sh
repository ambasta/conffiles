#!/bin/bash

function make_symlink() {
	DIR=$(dirname "$1")
	FILE=$(basename "$1")
	DIR_NO_CWD_PREFIX=${DIR#"$2"}
	DIR_TARGET="${HOME}${DIR_NO_CWD_PREFIX}"
	FILE_TARGET="${DIR_TARGET}/${FILE}"

	if [ -f "$FILE_TARGET" ] || [ -d "$FILE_TARGET" ]
	then
		rm -fr $FILE_TARGET
	fi
	mkdir -p $DIR_TARGET
	# echo "mkdir -p $DIR_TARGET"
	# echo "ln -s $1 ${DIR_TARGET}/${FILE}"
	ln -s $1 ${DIR_TARGET}/${FILE}
}

function explore_dir() {
    for file in $(find ${1} -maxdepth 1)
    do
	if [ $file = $1 ]
	then
		continue
	fi

	if [ -d $file ]
	then
		pushd $file > /dev/null
		curdir=$(pwd)
		submodule_test=$(git rev-parse --show-superproject-working-tree 2>&1)
		popd > /dev/null

		if [ -z "$submodule_test" ]
		then
			explore_dir $file $2
		else
			make_symlink $file $2
		fi
	else
		DIR="$(dirname "${file}")"
		FILE="$(basename "${file}")"
		make_symlink $file $2
	fi

    done
}

SOURCE="${BASH_SOURCE[0]}"

while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done

DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

explore_dir $DIR/homedir $DIR/homedir
