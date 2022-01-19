const { spawnSync } = require('child_process');

const SERVER_PATHS = require('./consts/SERVER_PATHS');

const execStrikerAccessDatabase = (
  args,
  options = {
    timeout: 10000,
    encoding: 'utf-8',
  },
) => {
  const { error, stdout, stderr } = spawnSync(
    SERVER_PATHS.usr.sbin['striker-access-database'].self,
    args,
    options,
  );

  if (error) {
    throw error;
  }

  if (stderr) {
    throw new Error(stderr);
  }

  let output;

  try {
    output = JSON.parse(stdout);
  } catch (stdoutParseError) {
    output = stdout;

    console.warn(
      `Failed to parse striker-access-database output [${output}]; error: [${stdoutParseError}]`,
    );
  }

  return {
    stdout: output,
  };
};

const accessDB = {
  query: (query, accessMode, options) => {
    const args = ['--query', query];

    if (accessMode) {
      args.push('--mode', accessMode);
    }

    return execStrikerAccessDatabase(args, options);
  },
  sub: (subName, subParams, options) => {
    const args = ['--sub', subName];

    if (subParams) {
      args.push('--sub-params', JSON.stringify(subParams));
    }

    const { stdout } = execStrikerAccessDatabase(args, options);

    return {
      stdout: stdout['sub_results'],
    };
  },
};

module.exports = accessDB;
