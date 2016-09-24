#!/bin/bash
#
# bashttpd.sh - a shell web server 
#

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

function set_headers() {
   local code=$1
   local content_type=${2:-application/octet-stream}
   echo -en "HTTP/1.0 $1 $(code_to_text $1)\n"
   echo -en "Content-Type: $content_type\n\n"
}

function abort_request() {
   set_headers ${1:-500}; shift 
   [ -n "$*" ] && echo $*
   exit
}

function send_response() {
   read -t 1 line || abort_request 400
   echo "[$(date +'%F %T')] $line" >&2

   set $line
   local method=$1 path=".${2%/}"
   grep -iq GET <<<"$method" || abort_request 405 $method: method not allowed

   # check that requested path exists
   [ -e "$path" ] || {
      abort_request 404 404: $path not found
   }

   [ -f "$path" ] && { set_headers 200 $(file -b --mime-type "$path"); cat "$path"; }
   [ -d "$path" ] && { set_headers 200 text/plain; ls --group-directories-first -lh "$path"; }
}


# start the server
[ ${RH:-0} -lt 1 ] && {
    # check for socat
    which socat >/dev/null 2>&1 || {
       echo "socat is required, please install it first"
       exit 1
    }

    # start listening
    echo "Starting server, listening on ${PORT:=8080}, press CTRL-C to exit..."
    socat TCP-LISTEN:$PORT,crlf,reuseaddr,fork SYSTEM:"RH=1 DEBUG=$DEBUG source $0; send_response"
}

