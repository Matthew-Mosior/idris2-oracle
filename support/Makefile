TARGET = liboracle-idris
TARGET_VERSION ?= 0.0.1

INSTALLDIR = ../lib

LDFLAGS =
CFLAGS = -O2 -g -Wall -Wextra -fPIC

CC_VERSION = $(shell $(CC) --version)

ifeq ($(findstring clang,$(CC_VERSION)),clang)
 DYLIB_WORKAROUND = cp "${INSTALLDIR}/${TARGET}" "${INSTALLDIR}/${TARGET}.dylib"
else
 DYLIB_WORKAROUND = cp "${INSTALLDIR}/${TARGET}" "${INSTALLDIR}/${TARGET}.so"
 LDFLAGS += -fuse-ld=gold
endif

SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ -I $^

.PHONY: clean

clean :
	rm -f $(OBJS) $(TARGET)
	rm -rf $(INSTALLDIR)

.PHONY: install

install:
	mkdir -p $(INSTALLDIR)
	install $(TARGET) $(INSTALLDIR)
	$(DYLIB_WORKAROUND)
