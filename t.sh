#! /usr/bin/bash
for file in *.c *.h *.cf; do
	cp "$file" "../tmp/${file}.txt"
done
