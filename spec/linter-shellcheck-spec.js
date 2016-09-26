'use babel';

import * as path from 'path';

const cleanPath = path.join(__dirname, 'fixtures', 'clean.sh');
const badPath = path.join(__dirname, 'fixtures', 'bad.sh');

describe('The ShellCheck provider for Linter', () => {
  const lint = require('../lib/main.js').provideLinter().lint;

  beforeEach(() => {
    atom.workspace.destroyActivePaneItem();

    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('linter-shellcheck'),
      ])
    );
  });

  it('finds nothing wrong with a valid file', () => {
    waitsForPromise(() =>
      atom.workspace.open(cleanPath).then(editor => lint(editor)).then((messages) => {
        expect(messages.length).toBe(0);
      })
    );
  });

  it('handles messages from ShellCheck', () => {
    const expectedMsg = 'Tips depend on target shell and yours is unknown. Add a shebang. ' +
      '[<a href="https://github.com/koalaman/shellcheck/wiki/SC2148">SC2148</a>]';
    waitsForPromise(() =>
      atom.workspace.open(badPath).then(editor => lint(editor)).then((messages) => {
        expect(messages.length).toBe(1);
        expect(messages[0].type).toBe('error');
        expect(messages[0].text).not.toBeDefined();
        expect(messages[0].html).toBe(expectedMsg);
        expect(messages[0].filePath).toBe(badPath);
        expect(messages[0].range).toEqual([[0, 0], [0, 4]]);
      })
    );
  });
});
