# pandoc-vimhelp

A lua writer for pandoc that output vim help files.

Usage example:

```shell
pandoc -f README.md -t /path/to/pandoc-vimhelp/vimhelp.lua -o doc/plugin.txt
```

For more examples, see the [test](test/) directory.

## The structure of the generated file

The outline of the generated file is:

```
filename.txt description

CONTENTS *title-content*

1. Intro             |title|
2. Section 1         |section-1|
   2.1. Subsection 1 |subsection-1|

(content)


 vim:tw=78:ft=help:norl:ambw=single
```

If `raw` metadata is `true`, only the `(content)` part will be output,
and the table of content is output into the `toc` metadata.
If `title` metadata is not present, the first `h1` is treated as the title,
and following `h1`s would trigger an warning message.
If `filename` metadata is not present, the title is used as the filename.

Only two levels of section is put into TOC, 'subsubsection's are translated into `subsubsection~` without a link,
and sections of higher levels are translated into links, commands, functions and option variables
are recognized (correctly, hopefully).

Content before the first non-title heading is used to form the `Intro` section if it's not empty.

Links with a target (or are created a target by pandoc) are translated to be surrounded by bars (`|`),
otherwise, they are translated to be surrounded by backticks (`` ` ``)
if the text is not surrounded by single quotes (`'`).
However, the surrounding char in the target (if present) is preserved.
If text is provided to a link, it is translated into `text(link)`,
where `link` is translated in the rule; to use a "raw" link, use `[](link)` in markdown.

## TODO

- [ ] Add reader.

- [ ] Turn to a GitHub action.

- [ ] Add better support for other writing systems:

  - [ ] East Asian
  - [ ] RTL

