{CompositeDisposable} = require 'atom'

module.exports =
  config:
    executablePath:
      type: 'string'
      title: 'Shellcheck Executable Path'
      default: 'shellcheck' # Let OS's $PATH handle the rest

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-shellcheck.executablePath',
      (executablePath) =>
        @executablePath = executablePath

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
        command = @executablePath
        parameters = []
        parameters.push('-f', 'gcc', filePath)
        return helpers.exec(command, parameters).then (output) ->
          regex = /.+?:(\d+):(\d+):\s(warning|error):\s(.+)/g
          messages = []
          while((match = regex.exec(output)) isnt null)
            messages.push
              type: match[3]
              filePath: filePath
              range: helpers.rangeFromLineNumber(textEditor, match[1] - 1)
              text: match[4]
          return messages
