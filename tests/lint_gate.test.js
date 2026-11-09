const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { spawnSync } = require('node:child_process');

const baseline = JSON.parse(readFileSync('tools/lint-baseline.json', 'utf8'));

function run(command, args) {
  const result = spawnSync(command, args, { encoding: 'utf8' });
  if (result.error) throw result.error;
  return result;
}

test('Biome diagnostics do not grow', () => {
  const result = run('npx', ['biome', 'check', '--reporter=json', 'tools/', 'tests/']);
  const summary = JSON.parse(result.stdout).summary;
  assert.ok(summary.errors <= baseline.biome_errors,
    `Biome errors ${summary.errors} > baseline ${baseline.biome_errors}`);
  assert.ok(summary.warnings <= baseline.biome_warnings,
    `Biome warnings ${summary.warnings} > baseline ${baseline.biome_warnings}`);
});

test('checkJs errors do not grow', () => {
  const result = run('npx', ['tsc', '-p', 'tools/tsconfig.json', '--noEmit']);
  const output = `${result.stdout}\n${result.stderr}`;
  const count = (output.match(/error TS\d+:/g) || []).length;
  assert.ok(count <= baseline.ts_errors,
    `TypeScript errors ${count} > baseline ${baseline.ts_errors}`);
});
