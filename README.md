# latex-words-since.nvim

A lightweight Neovim plugin for LaTeX writers that tracks real-time word count progress against your last Git commit. It parses your project using `texcount`, handles multi-file projects automatically via a `main.tex` root fallback, and safely calculates your additions inside an isolated system sandbox.

## Features

- **Accurate Prose Counts**: Leverages `texcount` to ignore LaTeX macros, preambles, and comment lines.
- **Git Commit Delta**: Shows exactly how many words you have added since your last `HEAD` commit.
- **Multi-file Project Support**: Automatically detects your Git root and prioritizes parsing from `main.tex` if it exists.
- **Isolated Footprint**: Uses a secure temp-directory sandbox to parse historical commits without touching your working tree assets.

## Requirements

This plugin requires the following external binaries available in your system `$PATH`:
- `texcount` (included by default in most TeX Live installations)
- `git`
- `tar`

## Installation

Install the plugin using **Lazy.vim**:

```lua
return {
   "chesed/latex-words-since.nvim",
   name = "latex-words-since",
   ft = "tex",
   opts = {
      separator = " || ", -- Custom string splitting additions from historical total
   },
   config = function(_, opts)
      require("latex-words-since").setup(opts)
   end,
}
```

## Configuration

You can customize the string separator by passing options into the `opts` block during initialization:

```lua
opts = {
   separator = " ── ",
}
```

## Usage

The plugin exposes a single user command. Execute it while working inside any tracked Git repository containing a LaTeX document:

```vim
:LatexWordsSince
```

### Output Format

The plugin evaluates your text and prints out a metrics string directly to your command line area:

```text
+ 245 || 1850 words
```

- **`+ 245`**: Words written and saved since your last Git commit.
- **`1850 words`**: Total prose word count recorded at your last Git commit checkpoint.
