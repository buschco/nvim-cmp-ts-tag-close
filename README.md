# nvim-cmp-ts-tag-close

A [`nvim-cmp`](https://github.com/hrsh7th/nvim-cmp)
source for closing tags provided by
[`treesitter`](https://github.com/nvim-treesitter/nvim-treesitter).

Heavily inspired by [`nvim-ts-autotag`](https://github.com/windwp/nvim-ts-autotag/) ❤️

<video src="https://user-images.githubusercontent.com/14929556/229447865-58af5ed5-decc-4fd4-a091-93c445fad90b.mov" width="100%"></video>

## Setup

### Install ([lazy.nvim](https://github.com/folke/lazy.nvim))

```lua
  {
    'nvim-treesitter/nvim-treesitter',
    -- [...]
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'buschco/nvim-cmp-ts-tag-close',
    }
  }
```

### Configure

```lua
require('nvim-cmp-ts-tag-close').setup({ skip_tags = { 'img' } })
```

### Register

```lua
require('cmp').setup {
  sources = {
    { name = 'nvim-cmp-ts-tag-close' },
  }
}
```

### Disclaimer

Expect bugs 🐞🪲
