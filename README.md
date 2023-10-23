# nunit-Ceasy
Complies C code natively and links it to NGINX Unit's `libunit.a` so you can register your native C app.

Inspired by the article [NGINX Unit Adds Assembly Language Support](https://www.nginx.com/blog/nginx-unit-adds-assembly-language-support/).



## Docker
1. Add required Unit header files to your C code. i.e.
```c
#include "nxt_clang.h"
#include "nxt_unit.h"
#include "nxt_unit_request.h"
#include "nxt_unit_typedefs.h"
```
**Unit source files will be included in the docker image, so you don't need local copies.**

2. Put your app source files in the `src/` directory.
3. Rename your maic C file to `main.c`; or change the expected file name in the `Dockerfile`.
4. Build the docker image:
  ```sh
  docker build -t nunit:latest .
  ```
5. Run the docker container:
  ```sh
  docker run --rm -p 8081:8081 nunit:latest
  ```
6. See your app running at `localhost:8081`!

## Local
### Requirements
Compiling `libunit.a` requires the Unit source code, see https://unit.nginx.org/installation/

1. Run
```sh
UNIT_SRC=/path/to/unit make prepare
```
to create `libunit.a` and copy over the necessary header to `include/`

2. Run `make`

3. Run your app `./app`

## Sample

1. Run
  ```sh
  UNIT_SRC=/path/to/unit make sample
  ```

2. Run`./sample` or build the docker image:
  ```sh
  docker build -t nunit:latest -f Dockerfile.sample .
  ```

