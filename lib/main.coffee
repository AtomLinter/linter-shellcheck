{CompositeDisposable} = require 'atom'

module.exports =
  config:
    shellcheckExecutablePath:
      type: 'string'
      title: 'Shellcheck Executable Path'
      default: 'shellcheck' # Let OS's $PATH handle the rest
    userParameters:
      type: 'string'
      title: 'Additional Executable Parameters'
      description:
        'Additional shellcheck parameters, for example `-x -e SC1090`.'
      default: ''
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
    @subscriptions.add atom.config.observe 'linter-shellcheck.userParameters',
      (userParameters) =>
        @userParameters = userParameters.trim().split(' ').filter(Boolean)

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    helpers = require('atom-linter')
    path = require('path')
    provider =
      grammarScopes: ['source.shell']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        text = textEditor.getText()
        cwd = path.dirname(filePath)
        showAll = @enableNotice
        # the first -f parameter overrides any others
        parameters = [].concat ['-f', 'gcc'], @userParameters, ['-']
        return helpers.exec(@executablePath, parameters,
          {stdin: text, cwd: cwd}).then (output) ->
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
