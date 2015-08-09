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

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe \
     'linter-shellcheck.shellcheckExecutablePath',
      (executablePath) =>
        @executablePath = executablePath
    @subscriptions.add atom.config.observe 'linter-shellcheck.enableNotice',
      (enableNotice) =>
        @enableNotice = enableNotice

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
