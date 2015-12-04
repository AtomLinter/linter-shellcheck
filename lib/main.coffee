{CompositeDisposable} = require 'atom'

module.exports =
  config:
    shellcheckExecutablePath:
      type: 'string'
      title: 'Shellcheck Executable Path'
      default: 'shellcheck' # Let OS's $PATH handle the rest
    enableNotice:
      type: 'boolean'
      title: 'Enable Notice Messages'
      default: false
    enableFixPath:
      type: 'boolean'
      title: 'Enable fix-path'
      description: 'Fix the `$PATH` on OS X when Atom is run from a GUI app.'
      default: process.platform is 'darwin'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe \
     'linter-shellcheck.shellcheckExecutablePath',
      (executablePath) =>
        @executablePath = executablePath
    @subscriptions.add atom.config.observe 'linter-shellcheck.enableNotice',
      (enableNotice) =>
        @enableNotice = enableNotice
    @subscriptions.add atom.config.observe 'linter-shellcheck.enableFixPath',
      (enableFixPath) ->
        # can not reverse fix-path once loaded
        require('fix-path')() if enableFixPath

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    helpers = require('atom-linter')
    provider =
      grammarScopes: ['source.shell']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        text = textEditor.getText()
        showAll = @enableNotice
        parameters = ['-f', 'gcc', '-' ]
        return helpers.exec(@executablePath, parameters,
         {stdin: text}).then (output) ->
          regex = /.+?:(\d+):(\d+):\s(\w+?):\s(.+)/g
          messages = []
          while((match = regex.exec(output)) isnt null)
            if showAll or match[3] == "warning" or match[3] == "error"
              lineStart = match[1] - 1
              colStart = match[2] - 1
              lineEnd = match[1] - 1
              colEnd = textEditor.getBuffer().lineLengthForRow(lineStart)
              messages.push
                type: match[3]
                filePath: filePath
                range: [ [lineStart, colStart], [lineEnd, colEnd] ]
                text: match[4]
          return messages
