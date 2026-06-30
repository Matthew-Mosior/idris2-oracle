IDRIS := idris2

TARGET = oracle-idris
TARGET_VERSION ?= 0.1.0

INSTALLDIR = `${IDRIS} --libdir`/oracle-${TARGET_VERSION}
LIBDIR = "${INSTALLDIR}/lib"

LDFLAGS =
CFLAGS = -O2 -g -Wall -Wextra -fPIC

CC_VERSION = $(shell $(CC) --version)

ifeq ($(findstring clang,$(CC_VERSION)),clang)
 DYLIB_WORKAROUND = cp "$(LIBDIR)/$(TARGET)" "$(LIBDIR)/$(TARGET).dylib"
else
 DYLIB_WORKAROUND = cp "$(LIBDIR)/$(TARGET)" "$(LIBDIR)/$(TARGET).so"
 LDFLAGS += -fuse-ld=lld
endif

SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ $^

.PHONY: clean

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: install

install:
	mkdir -p $(LIBDIR)
	install $(TARGET) $(LIBDIR)
	$(DYLIB_WORKAROUND)
