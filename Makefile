unit_include_dir = -I./include
nxt_unit_app = $(UNIT_SRC)/src/test/nxt_unit_app_test.c

CFLAGS ?= $(unit_include_dir) -g -O2 -fstack-protector-strong -Wall -Wextra -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2 -fPIC
LDFLAGS ?= -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -L. -lc -l:libunit.a -lpthread

all: app

app:
	cc $(CFLAGS) ./src/main.c -o app $(LDFLAGS) && chmod +x app

prepare: libunit.a unit-headers

unit-headers: | include/nxt_unit_typedefs.h include/nxt_clang.h include/nxt_unit_request.h include/nxt_unit_sptr.h include/nxt_unit_field.h include/nxt_unit.h

include/nxt_unit.h:
	cp $(UNIT_SRC)/src/nxt_unit.h ./include/nxt_unit.h
	sed -i '/^#include "nxt_auto_config.h"/d' ./include/nxt_unit.h
	sed -i '/^#include "nxt_version.h"/d' ./include/nxt_unit.h

include/nxt_clang.h:
	cp $(UNIT_SRC)/src/nxt_clang.h ./include/nxt_clang.h

include/nxt_unit_request.h:
	cp $(UNIT_SRC)/src/nxt_unit_request.h ./include/nxt_unit_request.h

include/nxt_unit_typedefs.h:
	cp $(UNIT_SRC)/src/nxt_unit_typedefs.h ./include/nxt_unit_typedefs.h

include/nxt_unit_sptr.h:
	cp $(UNIT_SRC)/src/nxt_unit_sptr.h ./include/nxt_unit_sptr.h

include/nxt_unit_field.h:
	cp $(UNIT_SRC)/src/nxt_unit_field.h ./include/nxt_unit_field.h

libunit.a: $(UNIT_SRC)/build/Makefile
	$(MAKE) -C $(UNIT_SRC) DESTDIR=./ libunit-install

$(UNIT_SRC)/build/Makefile: $(UNIT_SRC)/build
	$($UNIT_SRC/configure)

$(UNIT_SRC)/build: $(UNIT_SRC)

$(UNIT_SRC)/src/test/nxt_unit_app_test.c: $(UNIT_SRC)

sample: sample.c Dockerfile.sample
	cc $(CFLAGS) ./sample-dir/sample.c -o sample $(LDFLAGS) && chmod +x sample

sample.c: $(UNIT_SRC)/src/test/nxt_unit_app_test.c | sample-dir/
	cp $(UNIT_SRC)/src/test/nxt_unit_app_test.c ./sample-dir/sample.c

sample-dir/:
	mkdir sample-dir

Dockerfile.sample:
	cp Dockerfile Dockerfile.sample
	sed -i 's/COPY --link \.\/src\/\*/COPY --link \.\/sample-dir\/\*/' Dockerfile.sample
	sed -i 's/main.c/sample.c/g' Dockerfile.sample

.PHONY: clean libunit.a
clean:
	rm -f app
