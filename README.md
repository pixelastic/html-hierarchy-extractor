# html-hierarchy-extractor

## ⚠ DEPRECATION NOTICE

This gem has been deprecated in favor of [algolia_html_extractor][1]. No further
development will be happening on that gem. The new gem took over where this one
stopped.

## Description

This gems lets you extract the hierarchy of headings and content from any HTML
page into an array of elements.


Intended to be used with [Algolia][2] to improve relevance of search
results inside large HTML pages. The records created are compatible with the
[DocSearch][3] format.

## Installation

```ruby
# Gemfile
source 'http://rubygems.org'

gem 'html-hierarchy-extractor', '~> 1.0'
```

## How to use

```ruby
require 'html-hierarchy-extractor'

content = File.read('./index.html')
page = HTMLHierarchyExtractor.new(content)
records = page.extract
puts records
```

## Records

`extract` will return an array of records. Each record will represent a `<p>`
paragraph of the initial text, along with it textual version (HTML removed),
heading hierarchy, and other interesting bits.

## Example

Let's take the following HTML as input and see what records we got as output:

```html
<!doctype html>
<html>
<body>
  <h1 name="journey">The Hero's Journey</h1>
  <p>Most stories always follow the same pattern.</p>
  <h2 name="departure">Part One: Departure</h2>
  <p>A story starts in a mundane world, and helps identify the hero. It helps puts all the achievements of the story into perspective.</p>
  <h3 name="calladventure">The call to Adventure</h3>
  <p>Some out-of-the-ordinary event pushes the hero to start his journey.</p>
  <h3 name="threshold">Crossing the Threshold</h3>
  <p>The hero quits his job, hits the road, or whatever cuts him from his previous life.</p>
  <h2 name="initiations">Part Two: Initiation</h2>
  <h3 name="trials">The Road of Trials</h3>
  <p>The road is filled with dangers. The hero as to find his inner strength to overcome them.</p>
  <h3 name="ultimate">The Ultimate Boon</h3>
  <p>The hero has found something, either physical or metaphorical that changes him.</p>
  <h2 name="return">Part Three: Return</h2>
  <h3 name="refusal">Refusal to Return</h3>
  <p>The hero does not want to go back to his previous life at first. But then, an event will make him change his mind.</p>
  <h3 name="master">Master of Two Worlds</h3>
  <p>Armed with his new power/weapon, the hero can go back to its initial world and fix all the issues he had there.</p>
</body>
</html>
```

Here is one of the records extracted:

```ruby
{
  :uuid => "1f5923d5a60e998704f201bbe9964811",
  :tag_name => "p",
  :html => "<p>The hero quits his job, hits the road, or whatever cuts him from his previous life.</p>",
  :text => "The hero quits his job, hits the road, or whatever cuts him from his previous life.",
  :node => #<Nokogiri::XML::Element:0x11a5850 name="p">,
  :anchor => 'threshold',
  :hierarchy => {
    :lvl0 => "The Hero's Journey",
    :lvl1 => "Part One: Departure",
    :lvl2 => "Crossing the Threshold",
    :lvl3 => nil,
    :lvl4 => nil,
    :lvl5 => nil,
    :lvl6 => nil
  },
  :weight => {
    :heading => 70,
    :position => 3
  }
}
```

Each record has a `uuid` that uniquely identify it (computed by a hash of all
the other values).

It also contains the HTML tag name in `tag_name` (by default `<p>`
paragraphs are extracted, but see the [settings][4] on how to change it).

`html` contains the whole `outerContent` of the element, including the wrapping
tags and inner children. The `text` attribute contains the textual content,
stripping out all HTML.

`node` contains the [Nokogiri node][5] instance. The lib uses it internally to
extract all the relevant information but is also exposed if you want to process
the node further.

The `anchor` attributes contains the HTML anchor closest to the element. Here it
is `threshold` because this is the closest anchor in the hierarchy above.
Anchors are searched in `name` and `id` attributes of headings.

`hierarchy` then contains a snapshot of the current heading hierarchy of the
paragraph. The `lvlX` syntax is used to be compatible with the records
[DocSearch][6] is using.

The `weight` attribute is used to provide an easy way to rank two records
relative to each other.

- `heading` gives the depth level in the hierarchy where the record is. Records
  on top level will have a value of 100, those under a `h1` will have 90, and so
  on. Because our record is under a `h3`, it has 70.
- `position` is the position of the paragraph in the page. Here our paragraph is
  the fourth paragraph of the page, so it will have a `position` of 3. It can
  help you give more weight to the first items in the page.

## Settings

When instanciating `HTMLHierarchyExtractor`, you can pass a secondary `options`
argument. This attribute accepts one value, `css_selector`.

```ruby
page = HTMLHierarchyExtractor.new(content, { css_selector: 'p,li' })
```

This lets you change the default selector. Here instead of `<p>` paragraph,
the library will extract `<li>` list elements as well.

# CONTRIBUTING

I'm happy you'd like to contribute. All contributions are welcome, ranging from
feature requests to pull requests, but also including typo fixing, documentation
and generic bug reports.

## Bug Reports and feature requests

For any bug or ideas of new features, please start by checking in the
[issues][7] tab if
it hasn't been discussed already. If not, feel free to open a new issue.

## Pull Requests

All PR are welcome, from small typo fixes to large codebase changes. If you
think you'll need to change a lot of code in a lot of files, I would suggest you
to open an issue first so we can discuss before you start working on something.

All PR should be based on the `develop` branch (`master` only ever contains the
last released change).

## Git Hooks

If you start working on the actual code, you should install the git hooks.

```
cp ./scripts/git_hooks/* ./.git/hooks
```

This will add a `pre-commit` and `pre-push` scripts that will respectively check
that all files are lint-free before committing, and pass all tests before
pushing. If any of those two hooks give your errors, you should fix the code
before committing or pushing.

Having those steps helps keeping the codebase clean as much as possible, and
avoid polluting discussion in PR about style.

## Development

First thing you should do to get all your dependencies up to date is run `bundle
install` before running any other command.

## Lint

`rake lint` will check all the files for potential linting issue. It uses
Rubocop, and the configuration can be found in `.rubocop.yml`.

## Test

`rake test` will run all the tests.

`rake coverage` will do the same, but also adding the code coverage files to
`./coverage`. This should be useful in a CI environment.

`rake watch` will run Guard that will do a live run of all your tests. Every
update to a file (code or test) will re-run all the bound tests. This is highly
recommended for TDD.

## Using a local version of the gem

If you want to test a local version of the gem in your local project, I suggest
updating your project `Gemfile` to point to the correct local directory

```ruby
gem "html-hierarchy-extractor", :path => "/path/to/local/gem/folder"
```

You should also run `rake gemspec` from the `html-hierarchy-extractor`
repository the first time and if you added/deleted any file or dependency.


[1]: https://github.com/algolia/html-extractor
[2]: https://www.algolia.com/
[3]: https://community.algolia.com/docsearch/
[4]: #Settings
[5]: http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Node
[6]: https://community.algolia.com/docsearch/
[7]: https://github.com/pixelastic/html-hierarchy-extractor/issues
