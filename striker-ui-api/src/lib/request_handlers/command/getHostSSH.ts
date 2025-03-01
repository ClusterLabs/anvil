import { RequestHandler } from 'express';

import { HOST_KEY_CHANGED_PREFIX } from '../../consts';

import { getHostFromTarget, getPeerData, query } from '../../accessModule';
import { Responder } from '../../Responder';
import { getHostSshRequestBodySchema } from './schemas';

export const getHostSSH: RequestHandler<
  undefined,
  GetHostSshResponseBody | ResponseErrorBody,
  GetHostSshRequestBody
> = async (request, response) => {
  const { body } = request;

  const respond = new Responder(response);

  let sanitized: Required<GetHostSshRequestBody>;

  try {
    sanitized = await getHostSshRequestBodySchema.validate(body);
  } catch (error) {
    return respond.s400('39bff39', `Invalid request body; CAUSE: ${error}`);
  }

  const { password, port, target } = sanitized;

  let responseBody: GetHostSshResponseBody;

  try {
    responseBody = await getPeerData(target, {
      password,
      port,
    });
  } catch (error) {
    return respond.s500('fe14fb1', `Failed to get peer data; CAUSE: ${error}`);
  }

  const badKeys: string[] = [];

  let badHostUuid: string | undefined;

  try {
    // The test access is done with the given target. If there is a bad key
    // problem, it will be stored in the states table with the target in the
    // state name.

    // Filter and format the state values before doing the final match.
    const sqlGetStates = `
      SELECT
        state_uuid,
        SUBSTRING(state_name, '${HOST_KEY_CHANGED_PREFIX}(.*)') AS target,
        SUBSTRING(state_note, 'key=(.*)') AS key
      FROM states
      WHERE state_name LIKE '${HOST_KEY_CHANGED_PREFIX}%'`;

    // Try to get the key with matching target. Other key(s) linked to the same
    // host will be handled by the job.
    const sqlGetKey = `
      SELECT
        a.key
      FROM (${sqlGetStates}) AS a
      WHERE
        a.target = '${target}'`;

    const rows = await query<[string][]>(`${sqlGetKey};`);

    if (rows.length) {
      const [badKey] = rows[0];

      badKeys.push(badKey);
    }

    badHostUuid = await getHostFromTarget(target);
  } catch (error) {
    return respond.s500(
      'd5a2acf',
      `Failed to list SSH key conflicts; CAUSE: ${error}`,
    );
  }

  if (badKeys.length > 0) {
    responseBody.badSshKeys = {
      badKeys,
      badHost: {
        uuid: badHostUuid,
      },
    };
  }

  return respond.s200(responseBody);
};
