#!/bin/bash

cat name-tag-list.txt | ./kpw2008-tag.pl tags
./merge-three.pl merge regular- tags/[01]*.png
./merge-three.pl merge speaker- tags/speaker*.png
./merge-three.pl merge staff- tags/staff*.png
