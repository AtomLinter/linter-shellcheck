'use babel';

import * as path from 'path';
// eslint-disable-next-line no-unused-vars
import { it, fit, wait, beforeEach, afterEach } from 'jasmine-fix';

const { lint } = require('../lib/main.js').provideLinter();

const cleanPath = path.join(__dirname, 'fixtures', 'clean.sh');
const badPath = path.join(__dirname, 'fixtures', 'bad.sh');
const sourceFileRelativePath = path.join(__dirname, 'fixtures', 'source_directive', 'file_relative.sh');
const sourceProjectRelativePath = path.join(__dirname, 'fixtures', 'source_directive', 'project_relative.sh');

describe('The ShellCheck provider for Linter', () => {
  beforeEach(async () => {
    atom.workspace.destroyActivePaneItem();

    // Info about this beforeEach() implementation:
    // https://github.com/AtomLinter/Meta/issues/15
    const activationPromise = atom.packages.activatePackage('linter-shellcheck');

    await atom.packages.activatePackage('language-shellscript');
    await atom.workspace.open(cleanPath);

    atom.packages.triggerDeferredActivationHooks();
    await activationPromise;
  });

  it('finds nothing wrong with a valid file', async () => {
    const editor = await atom.workspace.open(cleanPath);
    const messages = await lint(editor);

    expect(messages.length).toBe(0);
  });

  it('handles messages from ShellCheck', async () => {
    const expectedMsg = 'Tips depend on target shell and yours is unknown. Add a shebang. ' +
      '[<a href="https://github.com/koalaman/shellcheck/wiki/SC2148">SC2148</a>]';
    const editor = await atom.workspace.open(badPath);
    const messages = await lint(editor);

    expect(messages.length).toBe(1);
    expect(messages[0].type).toBe('error');
    expect(messages[0].text).not.toBeDefined();
    expect(messages[0].html).toBe(expectedMsg);
    expect(messages[0].filePath).toBe(badPath);
    expect(messages[0].range).toEqual([[0, 0], [0, 4]]);
  });

  describe('implements useProjectCwd and', () => {
    beforeEach(async () => {
      atom.config.set('linter-shellcheck.userParameters', '-x');
      atom.config.set('linter-shellcheck.enableNotice', true);
    });

    it('uses file-relative source= directives by default', async () => {
      atom.config.set('linter-shellcheck.useProjectCwd', false);
      const editor = await atom.workspace.open(sourceFileRelativePath);
      const messages = await lint(editor);
      expect(messages.length).toBe(0);
    });

    it('errors for file-relative source= path with useProjectCwd = true', async () => {
      atom.config.set('linter-shellcheck.useProjectCwd', true);
      const editor = await atom.workspace.open(sourceFileRelativePath);
      const messages = await lint(editor);
      expect(messages.length).toBe(1);
      expect(messages[0].html).toMatch(/openBinaryFile: does not exist/);
    });

    it('uses project-relative source= directives via setting (based at fixtures/)', async () => {
      atom.config.set('linter-shellcheck.useProjectCwd', true);
      const editor = await atom.workspace.open(sourceProjectRelativePath);
      const messages = await lint(editor);
      expect(messages.length).toBe(0);
    });

    it('errors for project-relative source= path with useProjectCwd = false (based at fixtures/)', async () => {
      atom.config.set('linter-shellcheck.useProjectCwd', false);
      const editor = await atom.workspace.open(sourceProjectRelativePath);
      const messages = await lint(editor);
      expect(messages.length).toBe(1);
      expect(messages[0].html).toMatch(/openBinaryFile: does not exist/);
    });
  });
});
