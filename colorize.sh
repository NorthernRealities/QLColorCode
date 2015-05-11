#!/bin/zsh

# This code is licensed under the GPL v2.  See LICENSE.txt for details.

# colorize.sh
# QLColorCode
#
# Created by Nathaniel Gray on 11/27/07.
# Copyright 2007 Nathaniel Gray.

# Expects   $1 = name of file to colorize
#           $2 = 1 if you want enough for a thumbnail, 0 for the full file
#
# Produces HTML on stdout with exit code 0 on success

###############################################################################

# Fail immediately on failure of sub-command
setopt err_exit

target=$1
thumb=$2

debug () {
if [ "x$qlcc_debug" != "x" ]; then if [ "x$thumb" = "x0" ]; then
    echo "QLColorCode: $@" 1>&2
fi; fi
}

debug Starting colorize.sh
#echo target is $target

hlDir=/usr/local/share/highlight
cmd=/usr/local/bin/highlight
cmdOpts=(-I -k "$font" -K $fontSizePoints --quiet -I  \
    --style=${hlTheme} \
    --encoding $textEncoding ${=extraHLFlags} --validate-input)

#for o in $cmdOpts; do echo $o\<br/\>; done

debug Setting reader
reader=(cat $target)

debug Handling special cases

case $target in
    *.graffle )
        # some omnigraffle files are XML and get passed to us.  Ignore them.
        exit 1
        ;;

    *.plist )
        lang=xml
        reader=(/usr/bin/plutil -convert xml1 -o - $target)
        ;;

    *.h )
        if grep -q "@interface" $target &> /dev/null; then
            lang=objc
        else
            lang=h
        fi
        ;;

    *.m )
        # look for a matlab-style comment in the first 10 lines, otherwise
        # assume objective-c.  If you never use matlab or never use objc,
        # you might want to hardwire this one way or the other
        if head -n 10 $target | grep -q "^[ 	]*%" &> /dev/null; then
            lang=m
        else
            lang=objc
        fi
        ;;

    *.pro )
        # Can be either IDL or Prolog.  Prolog uses /* */ and % for comments.
        # IDL uses ;
        if head -n 10 $target | grep -q "^[ 	]*;" &> /dev/null; then
            lang=idlang
        else
            lang=pro
        fi
        ;;

    *.pl )
        lang=perl
        ;;

    *.swift )
        lang=swift
        ;;

    LICENSE |\
    COPYING |\
    Podfile |\
    README )
        lang=txt
        ;;

    Makefile )
        lang=make
        ;;
esac

debug Resolved $target to language $lang

go4it () {
    debug Generating the preview

    # Same as basename $target
    local title=${target##*/}

    if [ $thumb = "1" ]; then
        $reader | head -n 100 | head -c 20000 | $cmd -S $lang $cmdOpts && exit 0
    elif [ -n "$maxFileSize" ]; then
        $reader | head -c $maxFileSize | $cmd -T "${title}" -S $lang $cmdOpts && exit 0
    else
        $reader | $cmd -S $lang -T "${title}" $cmdOpts && exit 0
    fi
}

setopt no_err_exit
debug First try...
go4it
# Uh-oh, it didn't work.  Fall back to rendering the file as plain
debug First try failed, second try...
lang=txt
go4it
debug Reached the end of the file.  That should not happen.
exit 101

