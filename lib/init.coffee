module.exports =
  configDefaults:
    shellcheckExecutablePath: process.env.PATH

  activate: ->
    console.log 'activate linter-shellcheck'
