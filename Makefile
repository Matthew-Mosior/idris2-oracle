.PHONY: build install test clean oracle-client oracle-client-check

build: oracle-client-check
	idris2 --clean oracle.ipkg
	idris2 --build oracle.ipkg

install: oracle-client-check
	idris2 --install oracle.ipkg

test: oracle-client-check
	idris2 --build oracle.ipkg
	idris2 --install oracle.ipkg
	cd test && \
		idris2 --build test.ipkg && \
		./build/exec/oracle-test

oracle-client: oracle-client-check

oracle-client-check:
	@echo "Checking Oracle Instant Client..."

	@if command -v ldconfig >/dev/null 2>&1 && ldconfig -p 2>/dev/null | grep -q libclntsh; then \
		echo "Oracle Client found."; \
	elif command -v where >/dev/null 2>&1 && where oraociei.dll > /dev/null 2>&1; then \
		echo "Oracle Client found."; \
	else \
		echo ""; \
		echo "ERROR: Oracle Instant Client was not found."; \
		echo ""; \
		echo "Install Oracle Instant Client before continuing."; \
		echo ""; \
		echo "Linux (Ubuntu/Debian):"; \
		echo "  Download Instant Client from:"; \
		echo "    https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html"; \
		echo ""; \
		echo "  Install dependencies:"; \
		echo "    sudo apt install libaio1"; \
		echo ""; \
		echo "  Install Instant Client:"; \
		echo "    sudo dpkg -i oracle-instantclient*.deb"; \
		echo ""; \
		echo "  Update linker cache:"; \
		echo "    sudo ldconfig"; \
		echo ""; \
		echo "Linux (Fedora/RHEL):"; \
		echo "  Install Instant Client:"; \
		echo "    sudo dnf install oracle-instantclient-release"; \
		echo "    sudo dnf install oracle-instantclient-basic"; \
		echo ""; \
		echo "Windows:"; \
		echo "  1. Download Oracle Instant Client:"; \
		echo "     https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html"; \
		echo ""; \
		echo "  2. Extract the ZIP file, for example:"; \
		echo "     C:\\oracle\\instantclient_23_x"; \
		echo ""; \
		echo "  3. Add that directory to your PATH:"; \
		echo "     Control Panel -> System -> Environment Variables"; \
		echo "     Add C:\\oracle\\instantclient_23_x"; \
		echo ""; \
		echo "  4. Restart your terminal."; \
		echo ""; \
		echo "  5. Verify:"; \
		echo "     where oraociei.dll"; \
		echo ""; \
		echo "macOS:"; \
		echo "  Download Instant Client:"; \
		echo "    https://www.oracle.com/database/technologies/instant-client/macos-intel-x86-downloads.html"; \
		echo ""; \
		echo "  Set library path:"; \
		echo "    export DYLD_LIBRARY_PATH=/path/to/instantclient:\$$DYLD_LIBRARY_PATH"; \
		echo ""; \
		exit 1; \
	fi

clean:
	idris2 --clean oracle.ipkg
	cd test && idris2 --clean test.ipkg
