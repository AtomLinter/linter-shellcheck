linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
findFile = require "#{linterPath}/lib/util"

class LinterShellcheck extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: 'source.shell'

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: 'shellcheck -f gcc'

  executablePath: null

  linterName: 'shellcheck'

  # A regex pattern used to extract information from the executable's output.
  regex:
    '.+?:(?<line>\\d+):(?<col>\\d+):\\s((?<error>error)|(?<warning>.+)):\\s(?<message>.+)'

  constructor: (editor)->
    super(editor)

    atom.config.observe 'linter-shellcheck.shellcheckExecutablePath', =>
      @executablePath = atom.config.get 'linter-shellcheck.shellcheckExecutablePath'

  destroy: ->
    atom.config.unobserve 'linter-shellcheck.shellcheckExecutablePath'

module.exports = LinterShellcheck
