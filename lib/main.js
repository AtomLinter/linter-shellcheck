'use babel';

/* eslint-disable import/no-extraneous-dependencies, import/extensions */
import { CompositeDisposable } from 'atom';
/* eslint-enable import/no-extraneous-dependencies, import/extensions */

// Some internal variables
const baseUrl = 'https://github.com/koalaman/shellcheck/wiki';
const errorCodeRegex = /SC\d{4}/;
const regex = /.+?:(\d+):(\d+):\s(\w+?):\s(.+)/g;

const createURL = (text) => {
  const match = errorCodeRegex.exec(text);
  if (match) {
    return `${baseUrl}/${match[0]}`;
  }
  return undefined;
};

export default {
  activate() {
    require('atom-package-deps').install('linter-shellcheck');

    this.subscriptions = new CompositeDisposable();
    this.subscriptions.add(
      atom.config.observe('linter-shellcheck.shellcheckExecutablePath', (value) => {
        this.executablePath = value;
      }),
      atom.config.observe('linter-shellcheck.enableNotice', (value) => {
        this.enableNotice = value;
      }),
      atom.config.observe('linter-shellcheck.userParameters', (value) => {
        this.userParameters = value.trim().split(' ').filter(Boolean);
      }),
      atom.config.observe('linter-shellcheck.useProjectCwd', (value) => {
        this.useProjectCwd = value;
      }),
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
      lintsOnChange: true,
      lint: (textEditor) => {
        if (!atom.workspace.isTextEditor(textEditor)) {
          return null;
        }

        const filePath = textEditor.getPath();
        if (!filePath) {
          // TextEditor has no path associated with it (yet)
          return null;
        }

        const fileExt = path.extname(filePath);
        if (fileExt === '.zsh' || fileExt === '.zsh-theme') {
          // shellcheck does not support zsh
          return [];
        }

        const text = textEditor.getText();
        const projectPath = atom.project.relativizePath(filePath)[0];
        const cwd = this.useProjectCwd && projectPath ? projectPath : path.dirname(filePath);
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
            const type = match[3] !== 'note' ? match[3] : 'info';
            if (showAll || type === 'warning' || type === 'error') {
              const line = Number.parseInt(match[1], 10) - 1;
              const col = Number.parseInt(match[2], 10) - 1;
              messages.push({
                severity: type,
                location: {
                  file: filePath,
                  position: helpers.generateRange(textEditor, line, col),
                },
                excerpt: match[4],
                url: createURL(match[4]),
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
