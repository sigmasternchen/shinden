#!/bin/bash

template() {
    eval "$2"
    _template="$1"

    _script=""
    _buffer=""
    _open=0
    _close=0
    _justHadNewline=0
    _skipNextNewline=0

    _dumpRawBuffer() {
        # {{ can not occour in raw _buffer
        _script+="printf '%s' $(printf "{{%s{{" "$_buffer" | sed "s/'/'\"'\"'/g" | sed "s/{{/'/g")"
        _script+=$'\n'
        _buffer=""
    }

    _dumpCommandBuffer() {
        _script+="$_buffer"
        _script+=$'\n'
        _buffer=""
    }

    _dumpOpen() {
        for i in $(seq $_open); do
            _buffer+="{"
        done
        _open=0
    }
    _dumpClose() {
        for i in $(seq $_close); do
            _buffer+="}"
        done
        _close=0
    }

    while read -r -N1 c; do
        if test "$c " = '{ ' -a $_open -ne 2; then
            if test $_open = 0; then
                if test $_close = 1; then
                    _buffer+="}"
                    _close=0
                fi
                _open=1
            else
                _open=2
                _dumpRawBuffer
                if test $_justHadNewline -eq 1; then
                    _skipNextNewline=1
                fi
            fi
        elif test "$c " = '} ' -a "$_open" -eq 2; then
            if test $_close = 0; then
                _close=1
            else
                _open=0
                _close=0
                _dumpCommandBuffer
            fi
        else
            if test $_open -ne 2; then
                _dumpOpen
                _dumpClose
            elif test $_open -eq 2 -a $_close -ne 0; then
                _dumpClose
            fi
            if test "$c " = $'\n ' -o "$c " = $'\r '; then
                _justHadNewline=1
                if test $_skipNextNewline -eq 0; then
                    _buffer+="$c"
                fi
            else
                _justHadNewline=0
                _buffer+="$c"
            fi
            if test $_open -ne 2; then
                _skipNextNewline=0
            fi
        fi
    done < $_template

    _dumpOpen
    _dumpClose
    _dumpRawBuffer

    print() {
        printf '%s' "$@"
    }

    #echo "$_script" >&2
    eval "$_script"
}
