.PHONY: test

test:
	nvim --headless -u tests/minimal_init.lua \
		-c "if !exists(':PlenaryBustedDirectory') | echoerr 'plenary.nvim not found. Set PLENARY_PATH=/path/to/plenary.nvim or clone it next to this repository.' | cquit | endif" \
		-c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }"
