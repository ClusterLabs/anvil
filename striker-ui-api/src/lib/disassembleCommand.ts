/**
 * Assumes:
 * - the parameter of any flags must be quoted by single or double quotes when it contains space(s)
 *
 * TODO: replace with a package to handle parsing such command strings
 */
export const getHostIpmi = (command: string): HostIpmi => {
  const parts = command.split(/\s+/).filter((part) => Boolean(part));

  let flag = '';

  const entries = parts.reduce<Record<string, string>>((previous, part) => {
    if (/^--/.test(part)) {
      flag = part.replace(/--/, '');
    } else if (flag) {
      previous[flag] = part.replace(/^['"]|['"]$/g, '');
    }

    return previous;
  }, {});

  return {
    command,
    ip: entries.ip,
    password: entries.password,
    username: entries.username,
  };
};
