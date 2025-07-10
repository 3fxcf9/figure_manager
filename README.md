# Figure manager

## Installation

```nix
nix profile install github:3fxcf9/figure_manager
```

## Usage

- To create a new figure (`<C-f>` in insert mode after writing the figure name)
  ```vim
  inoremap <C-f> <Esc>:silent exec '.!figure_manager create "'.expand('%:h').'/figures/" "'.getline('.').'"'<CR><CR>:w<CR>
  ```
- To choose and edit a specific figure (`<C-f>` in normal mode)
  ```vim
  inoremap <C-f> <Esc>:silent exec '.!figure_manager create "'.expand('%:h').'/figures/" "'.getline('.').'"'<CR><CR>:w<CR>
  ```
