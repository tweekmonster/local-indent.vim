# Local Indent Guide

Display a guide for the current line's indent level.  This was taken from
[braceless.vim](https://github.com/tweekmonster/braceless.vim) and shouldn't be
used in conjunction with its highlighting, because that would just be silly.

![local-indent](https://cloud.githubusercontent.com/assets/111942/13067364/35c34d66-d43d-11e5-83f6-349a9427af88.gif)


## Usage

Turn it on using the `LocalIndentGuide` command with one of the following options:

Option | Description
------ | -----------
`+hl` | Enable highlighting
`-hl` | Disable highlighting
`+cc` | Enable `colorcolumn`
`-cc` | Disable `colorcolumn`

To enable it in any file type, add this to your vimrc:

```vim
autocmd FileType * LocalIndentGuide +hl +cc
```

To change the highlight color:

```vim
highlight LocalIndentGuide ctermfg=5 ctermbg=0 cterm=inverse
```

Note that it is a *foreground* color and that the style is *inverse*.  This
allows the highlight to be displayed while `colorcolumn` is enabled.


## License

MIT
