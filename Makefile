all: lua/luapack.lua

lua/%.lua: fnl/%.fnl
	fennel --compile $< > $@

