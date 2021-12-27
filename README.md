# pandoc-vimhelp

A lua writer for pandoc that output vim help files.

Usage example:

```shell
pandoc -f README.md -t /path/to/pandoc-vimhelp/vimhelp.lua -o doc/plugin.txt
```

## The structure of the generated file

The outline of the generated file is:

```
filename.txt description

CONTENTS *title-content*

1. Intro             |title|
2. Section 1         |section-1|
   2.1. Subsection 1 |subsection-1|

(content)


 vim:tw=78:ts=8:noet:ft=help:norl:
```

If `raw` metadata is `true`, only the `(content)` part will be output,
and the table of content is output into the `toc` metadata.
If `title` metadata is not present, the first `h1` is treated as the title,
and following `h1`s would trigger an warning message.
If `filename` metadata is not present, the title is used as the filename.

Only two levels of section is recognized, 'subsubsection's are translated into `subsubsection~`,
and sections of higher levels are translated into links, commands and functions
are recognized (correctly, hopefully).

Content before the first non-title heading is used to form the `Intro` section if it's not empty.

Links with a target (or are created a target by pandoc) are translated to be surrounded by bars (`|`),
otherwise, they are translated to be surrounded by backticks (`` ` ``)
if the text is not surrounded by single quotes (`'`).
However, the surrounding char in the target (if present) is preserved.

## TODO

- [ ] Add reader.

