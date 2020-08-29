lua/%.lua: fnl/%.fnl
	fennel --compile $< > $@

