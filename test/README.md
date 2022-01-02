# pandoc-vimhelp

A lua writer for pandoc that output vim help files.

Usage example:

```shell
pandoc -f README.md -t /path/to/pandoc-vimhelp/vimhelp.lua -o doc/plugin.txt
```

For more examples and further document, see the [test](test/) directory.

## Overview

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

Since pandoc don't allow writers to operate template metadata currently,
the template frame is hard-coded in the writer.
If you want to customize the structure, you can modify it after it's generated,
or set `raw` in the metadata, so that only the `(content)` part is output.

The `filename` is automatically generated from the output file name passed to pandoc,
if the output file is not specified (i.e. output to stdout),
it is generated from the title.
You can also explicitly specify the value through the `filename` metadata.

`title` can be specified in the metadata, or generated from the first `h1`.
*Note* that there's not allowed to be any content before the header used as title,
or the behavior is undefined.
Also note that the level of title would affect how following headers of different levels
are processed, for more details, see [Headers](#headers).

Some other metadata are available and may affect formatting,
they are of the same semantic as corresponding vim options:
`textwidth`, `ambiwidth`, `rtl`.
`indentstr` metadata can be used to specify what string is used to indent one level.

## Translations

The markup language used in vim help lacks many features,
thus many elements are translated as-is without formatting.
At most, only a warning is given noting that this feature is not supported.
*NO* escaping is performed.

### Headers

Header levels are relative: if title is specified in the metadata,
sections are divided by `h1`s,
and if title is generated from the first `h1`,
sections are divided by `h2`s, and following `h1`s are marked as illegal.

There are only two kinds of section divisors in vim help,
so only two levels of sections is generated and put into table of contents.
'subsubsection's are translated into `subsubsection ~`, and no link is generated.

Headers of higher levels are formatted to be with a link,
functions and commands are recognized and correct forms of links are generated.

Contents before the first non-title header (if any) is collected into a `Intro` section
with the link anchor generated for `title` as its anchor.

### Links

Links with a target (or are created a target by pandoc) are translated to be surrounded by bars (`|`),
otherwise, they are translated to be surrounded by backticks (`` ` ``)
if the text is not surrounded by single quotes (`'`).
However, the surrounding char in the target (if present) is preserved.
If text is provided to a link, it is translated into `text(link)`,
where `link` is translated in the rule; to get a "raw" link, use `[](link)` in markdown.

### Lists

List items are indented.

## TODO

- [ ] Add reader.

- [ ] Turn to a GitHub action.

- [ ] Add better support for other writing systems:

  - [ ] East Asian
  - [ ] RTL

- [ ] Switch to simpler implement when pandoc supports

