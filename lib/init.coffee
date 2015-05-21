module.exports =
  config:
    shellcheckExecutablePath:
      type: 'string'
      default: ''

  activate: ->
    console.log 'activate linter-shellcheck'
