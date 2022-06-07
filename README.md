# git-format-staged

Port of [hallettj/git-format-staged](https://github.com/hallettj/git-format-staged) 
to Ruby.

Consider a project where you want all code formatted consistently. So you use
a formatter and/or linter. (For example [SwiftFormat][]) You want to make sure 
that everyone working on the project runs the formatter, add a git pre-commit
hook to run it. The naive way to write that hook would be to:

- get a list of staged files
- run the formatter on those files
- run `git add` to stage the results of formatting

The problem with that solution is it forces you to commit entire files. At
worst this will lead to contributors to unwittingly committing changes. At
best it disrupts workflow for contributors who use `git add -p`.

git-format-staged tackles this problem by running the formatter on the staged
version of the file. Staging changes to a file actually produces a new file
that exists in the git object database. git-format-staged uses some git
plumbing commands to send content from that file to your formatter. The command
replaces file content in the git index. The process bypasses the working tree,
so any unstaged changes are ignored by the formatter, and remain unstaged.

After formatting a staged file git-format-staged computes a patch which it
attempts to apply to the working tree file to keep the working tree in sync
with staged changes. If patching fails you will see a warning message. The
version of the file that is committed will be formatted properly - the warning
just means that working tree copy of the file has been left unformatted. The
patch step can be disabled with the `--no-update-working-tree` option.

[SwiftFormat]: https://github.com/nicklockwood/SwiftFormat

## How to install

Requires Ruby 2.7 or newer. Tests run on 2.7 and 3.0.

Install as a development dependency in a project that uses bundle to manage
Ruby dependencies:

    $ bundle add format-staged

Or install globally:

    $ gem install format-staged

## How to use

For detailed information run:

    $ [bundle exec] git-format-staged --help

The command expects a shell command to run a formatter, and one or more file
patterns to identify which files should be formatted. For example:

    $ git-format-staged --formatter 'prettier --stdin-filepath "{}"' '*.js'

That will format all `.js` files using `prettier`.

The formatter command must read file content from `stdin`, and output formatted
content to `stdout`.

Patterns are evaluated from left-to-right: if a file matches multiple patterns
the right-most pattern determines whether the file is included or excluded.

git-format-staged never operates on files that are excluded from version
control. So it is not necessary to explicitly exclude stuff like
`vendor/`.

The formatter command may include a placeholder, `{}`, which will be replaced
with the path of the file that is being formatted. This is useful if your
formatter needs to know the file extension to determine how to format or to
lint each file. For example:

    $ git-format-staged -f 'prettier --stdin-filepath "{}"' '*.js' '*.css'

Do not attempt to read or write to `{}` in your formatter command! The
placeholder exists only for referencing the file name and path.

### Check staged changes with a linter without formatting

Perhaps you do not want to reformat files automatically; but you do want to
prevent files from being committed if they do not conform to style rules. You
can use git-format-staged with the `--no-write` option, and supply a lint
command instead of a format command. Here is an example using ESLint:

    $ git-format-staged --no-write -f 'eslint --stdin --stdin-filename "{}" >&2' 'src/*.js'

If this command is run in a pre-commit hook, and the lint command fails the
commit will be aborted and error messages will be displayed. The lint command
must read file content via `stdin`. Anything that the lint command outputs to
`stdout` will be ignored. In the example above `eslint` is given the `--stdin`
option to tell it to read content from `stdin` instead of reading files from
disk, and messages from `eslint` are redirected to `stderr` (using the `>&2`
notation) so that you can see them.

### Why the Ruby port if there already is a fine Python implementation?

I don’t like Python ;)

But jokes aside, I am already setting up a Ruby environment (using [rbenv][]) for my 
projects to run [cocoapods][] and [fastlane][] and our git hooks. By using this port
we don’t need to ensure to have python available as well.


[rbenv]: https://github.com/rbenv/rbenv/
[cocoapods]: https://cocoapods.org/
[fastlane]: https://fastlane.tools/
