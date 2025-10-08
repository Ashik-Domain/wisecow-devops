#!/usr/bin/env bash

export PATH=$PATH:/usr/games

SRVPORT=4499

handleRequest() {
    mod=$(fortune)
    cat <<EOF
HTTP/1.1 200

<pre>$(cowsay "$mod")</pre>
EOF
}

prerequisites() {
    command -v cowsay >/dev/null 2>&1 || { echo "cowsay not found"; exit 1; }
    command -v fortune >/dev/null 2>&1 || { echo "fortune not found"; exit 1; }
}

main() {
    prerequisites
    echo "Wisdom server starting on port $SRVPORT..."

    while true; do
        nc -l -p $SRVPORT < <(handleRequest)
    done
}

main
