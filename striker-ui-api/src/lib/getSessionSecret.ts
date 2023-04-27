import assert from 'assert';

import { ECODE_SESSION_SECRET, VNAME_SESSION_SECRET } from './consts';

import { query, variable } from './accessModule';
import { openssl, stderr, stdout } from './shell';

export const getSessionSecret = async (): Promise<string> => {
  let sessionSecret: string;

  try {
    const rows: [sessionSecret: string][] = await query(
      `SELECT variable_value
        FROM variables
        WHERE variable_name = '${VNAME_SESSION_SECRET}';`,
    );

    assert(rows.length > 0, 'No existing session secret found.');

    ({
      0: [sessionSecret],
    } = rows);

    stdout('Found an existing session secret.');

    return sessionSecret;
  } catch (queryError) {
    stderr(`Failed to get session secret from database; CAUSE: ${queryError}`);
  }

  try {
    sessionSecret = openssl('rand', '-base64', '32').trim();

    stdout('Generated a new session secret.');
  } catch (sysError) {
    stderr(`Failed to generate session secret; CAUSE: ${sysError}`);

    process.exit(ECODE_SESSION_SECRET);
  }

  try {
    const vuuid = await variable({
      file: __filename,
      variable_name: VNAME_SESSION_SECRET,
      variable_value: sessionSecret,
    });

    stdout(`Recorded session secret as variable identified by ${vuuid}.`);
  } catch (subError) {
    stderr(`Failed to record session secret; CAUSE: ${subError}`);

    process.exit(ECODE_SESSION_SECRET);
  }

  return sessionSecret;
};
