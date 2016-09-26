'use babel';

/* eslint-disable import/no-extraneous-dependencies, import/extensions */
import { CompositeDisposable } from 'atom';
/* eslint-enable import/no-extraneous-dependencies, import/extensions */

// Some internal variables
const baseUrl = 'https://github.com/koalaman/shellcheck/wiki';
const errorCodeRegex = /SC\d{4}/;
const regex = /.+?:(\d+):(\d+):\s(\w+?):\s(.+)/g;

const linkifyErrorCode = text =>
  text.replace(errorCodeRegex, `<a href="${baseUrl}/$&">$&</a>`);

export default {
  activate() {
    require('atom-package-deps').install('linter-shellcheck');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-shellcheck.shellcheckExecutablePath', (value) => {
        this.executablePath = value;
      })
    );
    this.subscriptions.add(
      atom.config.observe('linter-shellcheck.enableNotice', (value) => {
        this.enableNotice = value;
      })
    );
    this.subscriptions.add(
      atom.config.observe('linter-shellcheck.userParameters', (value) => {
        this.userParameters = value.trim().split(' ').filter(Boolean);
      })
    );
  },

  deactivate() {
    this.subscriptions.dispose();
  },

  provideLinter() {
    const helpers = require('atom-linter');
    const path = require('path');

    return {
      name: 'ShellCheck',
      grammarScopes: ['source.shell'],
      scope: 'file',
      lintOnFly: true,
      lint: (textEditor) => {
        const filePath = textEditor.getPath();
        const text = textEditor.getText();
        const cwd = path.dirname(filePath);
        const showAll = this.enableNotice;
        // The first -f parameter overrides any others
        const parameters = [].concat(['-f', 'gcc'], this.userParameters, ['-']);
        const options = { stdin: text, cwd, ignoreExitCode: true };
        return helpers.exec(this.executablePath, parameters, options).then((output) => {
          if (textEditor.getText() !== text) {
            // The text has changed since the lint was triggered, tell Linter not to update
            return null;
          }
          const messages = [];
          let match = regex.exec(output);
          while (match !== null) {
            const type = match[3];
            if (showAll || type === 'warning' || type === 'error') {
              const line = Number.parseInt(match[1], 10) - 1;
              const col = Number.parseInt(match[2], 10) - 1;
              messages.push({
                type,
                filePath,
                range: helpers.rangeFromLineNumber(textEditor, line, col),
                html: linkifyErrorCode(match[4]),
              });
            }
            match = regex.exec(output);
          }
          return messages;
        });
      },
    };
  },
};
