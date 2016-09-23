{CompositeDisposable} = require 'atom'

baseUrl = "https://github.com/koalaman/shellcheck/wiki"
errorCodeRegex = /SC\d{4}/

linkifyErrorCode = (text) ->
  text.replace(errorCodeRegex, "<a href=\"#{baseUrl}/$&\">$&</a>")

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
    require('atom-package-deps').install('linter-shellcheck')

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
      name: 'ShellCheck'
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
        options = {stdin: text, cwd, ignoreExitCode: true}
        return helpers.exec(@executablePath, parameters, options)
          .then (output) ->
            regex = /.+?:(\d+):(\d+):\s(\w+?):\s(.+)/g
            messages = []
            while((match = regex.exec(output)) isnt null)
              if showAll or match[3] == "warning" or match[3] == "error"
                line = match[1] - 1
                col = match[2] - 1
                messages.push
                  type: match[3]
                  filePath
                  range: helpers.rangeFromLineNumber(textEditor, line, col)
                  html: linkifyErrorCode(match[4])
            return messages
