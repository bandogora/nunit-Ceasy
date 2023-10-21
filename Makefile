
unit_include_dir = -I$(UNIT_SRC)/src
nxt_unit_app = $(UNIT_SRC)/src/test/nxt_unit_app_test.c

CFLAGS ?= $(unit_include_dir) -g -O2 -fstack-protector-strong -Wall -Wextra -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2 -fPIC
LDFLAGS ?= -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -L. -lc -l:libunit.a -lpthread

all: app

app: libunit.a
	cc $(CFLAGS) ./src/main.c -o app $(LDFLAGS) && chmod +x app

.PHONY: libunit.a
libunit.a: $(UNIT_SRC)/build/Makefile
	$(MAKE) -C $(UNIT_SRC) DESTDIR=./ libunit-install

$(UNIT_SRC)/build/Makefile: $(UNIT_SRC)/build
	$($UNIT_SRC/configure)

$(UNIT_SRC)/build: $(UNIT_SRC)

$(UNIT_SRC)/src: $(UNIT_SRC)

sample: libunit.a backup_main
	cp $(UNIT_SRC)/src/test/nxt_unit_app_test.c ./src/main.c

backup_main:
	mv ./src/main.c ./src/main.bak

.PHONY: clean
clean:
	rm -f app
