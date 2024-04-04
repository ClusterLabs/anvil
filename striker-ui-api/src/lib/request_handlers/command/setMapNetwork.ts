import assert from 'assert';
import { RequestHandler } from 'express';

import { LOCAL, REP_UUID } from '../../consts';

import { variable } from '../../accessModule';
import { toHostUUID } from '../../convertHostUUID';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';

export const setMapNetwork: RequestHandler<
  { uuid: string },
  undefined,
  SetMapNetworkRequestBody
> = async (request, response) => {
  const {
    body: { value: rValue } = {},
    params: { uuid: rHostUuid },
  } = request;

  const value = sanitize(rValue, 'number');

  let hostUuid = sanitize(rHostUuid, 'string', { fallback: LOCAL });

  hostUuid = toHostUUID(hostUuid);

  poutvar({ hostUuid, value }, `Set map network variable with: `);

  try {
    assert(
      value in [0, 1],
      `Variable value must be a number boolean (0 or 1); got [${value}]`,
    );

    assert(
      REP_UUID.test(hostUuid),
      `Host UUID must be a valid UUIDv4; got [${hostUuid}]`,
    );
  } catch (error) {
    perr(`Assert failed when set map network variable; CAUSE: ${error}`);

    return response.status(400).send();
  }

  try {
    const result = await variable({
      file: __filename,
      variable_default: 0,
      varaible_description: 'striker_0202',
      variable_name: 'config::map_network',
      variable_section: 'config',
      variable_source_table: 'hosts',
      variable_source_uuid: hostUuid,
      variable_value: value,
    });

    assert(
      REP_UUID.test(result),
      `Result must be UUID of modified record; got: [${result}]`,
    );
  } catch (error) {
    perr(
      `Failed to set map network variable for host ${hostUuid}; CAUSE: ${error}`,
    );

    return response.status(500).send();
  }

  return response.status(204).send();
};
