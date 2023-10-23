unit_include_dir = -I./include
nxt_unit_app = $(UNIT_SRC)/src/test/nxt_unit_app_test.c

CFLAGS ?= $(unit_include_dir) -g -O2 -fstack-protector-strong -Wall -Wextra -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2 -fPIC
LDFLAGS ?= -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -L. -lc -l:lib/libunit.a -lpthread

all: app

app:
	cc $(CFLAGS) ./src/main.c -o app $(LDFLAGS) && chmod +x app

prepare: libunit.a include/nxt_clang.h

include/nxt_clang.h:
	cp $(UNIT_SRC)/src/nxt_clang.h $(CURDIR)/include/nxt_clang.h

libunit.a: $(UNIT_SRC)/build/Makefile
	$(MAKE) -C $(UNIT_SRC) DESTDIR=$(CURDIR) libunit-install
	rm -rf $(CURDIR)/include
	rm -rf $(CURDIR)/share
	rm -rf $(CURDIR)/lib
	mv $(CURDIR)/usr/local/* $(CURDIR)
	rm -rf $(CURDIR)/usr

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
