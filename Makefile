.PHONY: build install test clean

build:
	idris2 --build oracle.ipkg

install:
	idris2 --install oracle.ipkg

test:
	idris2 --build oracle.ipkg
	idris2 --install oracle.ipkg
	cd test && \
		idris2 --build test.ipkg && \
		./build/exec/oracle-test

clean:
	idris2 --clean oracle.ipkg
	cd test && idris2 --clean test.ipkg
