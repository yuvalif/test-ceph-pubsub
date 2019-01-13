#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "usage: create-files <#files> <prefix>"
    exit 1
fi

for i in $( seq 1 $1 ); do 
    echo "hello" > ${2}${i}.jpg; 
done

