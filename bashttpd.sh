#!/bin/bash
#
# bashttpd.sh - a shell web server
#

# defaults
: ${PORT:=8080}
: ${READ_TIMEOUT:=1}
: ${ROOT:=$PWD}

# enable debug
[ "${DEBUG:-0}" -gt 0 ] && set -x

function code_to_text() {
   local code=$1

   case $code in
      200) echo -n "OK"                    ;;
      400) echo -n "Bad Request"           ;;
      403) echo -n "Forbidden"             ;;
      404) echo -n "Not Found"             ;;
      405) echo -n "Method not allowed"    ;;
      500) echo -n "Internal Server Error" ;;
      *  ) echo -n "Something went wrong"
    esac
}

function url_decode() {
   echo "$1" | awk -niord '{printf RT?$0chr("0x"substr(RT,2)):$0}' RS=%..
}

function set_headers() {
   local code=$1
   local content_type=${2:-text/plain}
   echo -en "HTTP/1.0 $code $(code_to_text $code)\n"
   echo -en "Content-Type: $content_type\n\n"
}

function abort_request() {
   set_headers ${1:-500}
   [ -n "$2" ] && echo "$2" || code_to_text $1
   exit
}

function send_response() {
   read -rt $READ_TIMEOUT request || abort_request 400
   echo "[$(date +'%F %T')] $request" >&2

   set $request
   local method=$1 path="$(url_decode ".${2%/}")"

   # we support only GET
   grep -iq GET <<< $method || abort_request 405

   # check that requested path exists
   [ -e "$path" ] || abort_request 404

   # send file
   [ -f "$path" ] && { set_headers 200 "$(file -b --mime "$path")"; cat "$path"; return; }

   # send directory index
   [ -d "$path" ] && { set_headers 200 "text/plain; charset=utf-8"; ls --group-directories-first -lh "$path"; }
}

# handle request and exit
[ ${RH:-0} -gt 0 ] && {
   cd "$ROOT"
   send_response
   exit
}

# start the server
type -P socat &>/dev/null || {
   echo "socat is required, please install it first" >&2
   exit 1
}

[[ -d "$ROOT" && -r "$ROOT" ]] || {
   echo "directory '$ROOT' specified by ROOT variable doesn't exist or in-accessible" >&2
   exit 1
}

# start listening
echo "Starting server, listening on $PORT, press CTRL-C to exit..."
socat TCP-LISTEN:$PORT,reuseaddr,fork SYSTEM:"RH=1 DEBUG=$DEBUG /usr/bin/env bash $0"
