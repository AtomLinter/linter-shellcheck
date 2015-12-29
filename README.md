# linter-shellcheck

This linter plugin for [Linter][linter] provides an interface to
[shellcheck][shellcheck]. It will be used with files that have the "Shell"
syntax.

## Installation

Linter package must be installed in order to use this plugin. If Linter is not
installed, please follow the instructions [here][linter].

### `shellcheck` installation

Before using this plugin, you must ensure that `shellcheck` is installed on
your system. To install `shellcheck`, follow the guide on
[shellcheck github][shellcheck]

### Plugin installation

```ShellSession
apm install linter-shellcheck
```

## Settings

You can configure linter-shellcheck through Atom's Settings menu. If you
instead prefer editing the configuration by hand you can get to that by editing
`~/.atom/config.cson` (choose Open Your Config in Atom menu). The settings
available are:

*   `shellcheckExecutablePath`: The full path to the `shellcheck` executable.
Run `which shellcheck` to find where it is installed on your system.

*   `userParameters`: Any additional executable parameters to pass to
`shellcheck` when linting your files.

[linter]: https://github.com/atom-community/linter "Linter"
[shellcheck]: https://github.com/koalaman/shellcheck "ShellCheck"
