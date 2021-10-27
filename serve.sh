#!/bin/sh

# default values
host='0.0.0.0' port='8888' dir='./static'

usage(){
    echo "Usage: $(basename "$0") [-H HOST] [-p PORT] [-d DIR]"
}

while :; do
    case "${1}" in
        -h|--help)     usage; exit 0;;
        -p|--port)     port="${2}"; shift;;
        -H|--host)     host="${2}"; shift;;
        -d|--dir)      dir="${2}"; shift;;
        *)             break;;
    esac
    shift
done

echo "+ serving ${dir} on ${host}:${port}..."
python3 -m http.server "${port}" --bind "${host}" --directory "${dir}" 2>&1 >/dev/null

