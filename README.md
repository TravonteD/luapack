# Luapack - A simple package manager for Neovim

Luapack is a package manager that utilizes Neovim's built in packaging system (see `:h packages` for more information). It is intended for use with a primarily Lua configuration.

## Installation
### Before installing please read!! Luapack uses features from the latest neovim-nightly, it will *_not_* work if you are not on the latest build.

Using git:

Clone the repository into your preferred package directory under 'luapack/opt/luapack'
```sh
git clone https://github.com/travonted/luapack.git \
    ~/.local/share/nvim/site/pack/luapack/opt/luapack
```

## Usage

These instructions are all in Lua,  if you are doing this in your init.vim wrap the code in a `:lua` block
```vimscript
lua<<EOF
" Add lua code here
EOF
```

### Defining Plugins

#### Simple configuration
First in your init.vim do 

```vim
packadd luapack
```

This needs to be before any configuration that requires Luapack to be loaded

```lua
-- We use a global variable here so that we can re-use the same object throughout the configuration
Luapack = require('luapack')
Luapack.plugins = {
  { 'travonted/luapack' },
  { 'travonted/luajob' }
}
Luapack.load()
```

### Installing,Updating, and Cleaning Plugins

Call the appropriate function on the Luapack object that you defined

`:lua Luapack.install()`
`:lua Luapack.update()`
`:lua Luapack.clean()`

