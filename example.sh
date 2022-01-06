#!/bin/bash

. engine.sh

template "example.templ" "
    title='Users'
    users=(
        'Alice'
        'Bob'
    )
"
