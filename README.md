# BASH httpd

My attempt on create **dumb** HTTPD server using only `bash` and `socat`.
Don't expect much from it, just make some fun!

## Running

as simple as just invoking the script:

```shell
# will listen on port '8080', and the 'wwwroot' will be set to $PWD
./bashttpd.sh

# or specify port with 'PORT' environment variable:
PORT=8181 ./bashttpd.sh

# to change 'wwwroot', specify 'ROOT' environment variable:
ROOT=/tmp/wwwroot PORT=8181 ./bashttpd.sh
```

---

- Author: Alex Simenduev
- License: [wtfpl](http://www.wtfpl.net/txt/copying/)
