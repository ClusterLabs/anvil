import { RequestHandler } from 'express';

import { HOST_KEY_CHANGED_PREFIX } from '../../consts';

import { getPeerData, query } from '../../accessModule';
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

  let badKeys: string[];

  let badHostUuid: string | undefined;

  try {
    // Try matching the target with an IP to get the host UUID.
    const sqlGetUuidFromIp = `
      SELECT ip_address_host_uuid
      FROM ip_addresses
      WHERE ip_address_address = '${target}'
      LIMIT 1`;

    // Try matching the target with a host name to get the host UUID.
    const sqlGetUuidFromShort = `
      SELECT host_uuid
      FROM hosts
      WHERE host_name LIKE CONCAT(
        SUBSTRING('${target}', '^[^.]*'),
        '%'
      )
      LIMIT 1`;

    // Since the target can only be **either** a name or IP, 1/2 query will
    // return NULL. When there's a match, prioritize the one that isn't NULL.
    const sqlGetUuid = `
      SELECT
        COALESCE(a1.host_uuid, a2.ip_address_host_uuid) AS host_uuid
      FROM (${sqlGetUuidFromShort}) AS a1
      FULL JOIN (${sqlGetUuidFromIp}) AS a2
        ON TRUE`;

    // Filter and format the state values before doing the final match.
    const sqlGetStates = `
      SELECT
        state_uuid,
        SUBSTRING(state_name, '${HOST_KEY_CHANGED_PREFIX}(.*)') AS target,
        SUBSTRING(state_note, 'key=(.*)') AS key
      FROM states
      WHERE state_name LIKE '${HOST_KEY_CHANGED_PREFIX}%'`;

    // Get all IPs and the host name, then match them to the state records to
    // find all keys related to the target.
    const sqlGetKeys = `
      SELECT
        DISTINCT(d.key),
        a.host_uuid
      FROM (${sqlGetUuid}) AS a
      LEFT JOIN ip_addresses AS b
        ON a.host_uuid = b.ip_address_host_uuid
      LEFT JOIN hosts AS c
        ON a.host_uuid = c.host_uuid
      JOIN (${sqlGetStates}) AS d
        ON d.target LIKE ANY (
          ARRAY [
            b.ip_address_address,
            CONCAT(
              SUBSTRING(c.host_name, '^[^.]*'),
              '%'
            )
          ]
        )`;

    const rows = await query<[string, string][]>(`${sqlGetKeys};`);

    badKeys = rows.map(([badKey]) => badKey);

    if (rows.length) {
      // All keys should only relate to 0 or 1 host UUID; try the first record
      [, badHostUuid] = rows[0];
    }
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
