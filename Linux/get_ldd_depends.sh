#!/bin/bash
#
# Modificated version of UG's get_dll_depends.sh for Linux, changes:
# * removed find_dll() (not needed, ldd gives us the full path)
# * is_not_system_dll() (the libc so-files are removed by caller)

# prints dependecies
get_depends() {
        if [ -f "$1" ]; then
                ldd "$1" | grep -v 'not found' | awk '{ print $3 }'
        fi
}

if [ $# -eq 0 ]; then
	echo "Usage $0 <executable>"
	echo -e "\tRecursively generates dependencies of the executable (DLLs)."
	echo -e "\tExcludes paths containing /c/Windows (system DLLs) in MSYS path syntax."
	exit 1
fi

declare -A DONE # list of already processed DLLs

INITIAL=$1 # save root element to skip the program itself

while test $# -gt 0; do
        # skip already processed item
        if [ -n "${DONE[$1]}" ]; then
                shift
                continue
        fi
        # push dependencies of current item to stack
        for n in `get_depends "$1"`; do
                DLL="$n"
                if [ -z "$DLL" ]; then
                        continue
                fi
                if test -z "${DONE[$DLL]}"; then
                        echo "Adding $DLL" >&2
                        set -- "$@" "$DLL"
                else
                        echo "Not adding $DLL" >&2
                fi
        done
        # print the item (omit initial)
        if [ "$1" != "$INITIAL" ]; then
                echo $1
        fi
        DONE[$1]=1
        shift
done

