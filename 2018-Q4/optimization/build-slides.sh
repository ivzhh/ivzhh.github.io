#!/bin/sh

pandoc -t revealjs -s "${1%.*}".md -o "${1%.*}".html -V revealjs-url=https://revealjs.com
