# Figure Manager

## Installation

### For NixOS systems

```nix
nix profile install github:3fxcf9/figure_manager
```

or declare this repository as a flake input with

```nix
inputs.figure_manager = {
  url = "github:3fxcf9/figure_manager";
};
```

and install it in your configuration, for example in home-manager with

```nix
{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    inputs.figure_manager.packages.${pkgs.system}.figure_manager
  ];
}
```

### For other GNU/Linux systems

After installing the dependencies (`inkscape`, `tofi`, `scour`, and `inotify-tools` providing `inotifywait`), you can build this project by running

```bash
v -prod .
```

Then, place the generated binary (`figure_manager`) somewhere in your `$PATH`.

## Configuration

1. Put your `template.svg` file in `$XDG_CONFIG_HOME/course-manager/figures`.
2. Create a file named `include_code` in the same directory (`$XDG_CONFIG_HOME/course-manager/figures`) containing the code used to include a figure in a document. For example, with my custom note syntax, it would look like this:

   ```bash
   %fig <FIGURE_NAME>
       @[<FIGURE_PATH>]
   %
   ```

## Usage

This script is designed to be used with (neo)vim. Here are some suggested key mappings:

- To create a new figure (`<C-f>` in insert mode, after typing the figure name)

  ```vim
  inoremap <C-f> <Esc>:silent exec '.!figure_manager create "'.expand('%:h').'/figures/" "'.getline('.').'"'<CR><CR>:w<CR>
  ```

- To choose and edit a specific figure (`<C-f>` in normal mode)

  ```vim
  nnoremap <C-f> :silent exec '!figure_manager edit "'.expand('%:h').'/figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>
  ```
