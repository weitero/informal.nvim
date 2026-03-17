LUA ?= $(shell command -v luajit >/dev/null 2>&1 && echo luajit || echo lua)

.PHONY: test

test:
	@command -v $(LUA) >/dev/null 2>&1 || { echo "No Lua interpreter found (tried '$(LUA)')."; exit 1; }
	@echo "Running tests with $(LUA)"
	@$(LUA) tests/run.lua
