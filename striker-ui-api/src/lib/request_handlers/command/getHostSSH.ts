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

  const { password, port, ipAddress: target } = sanitized;

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

  try {
    const rows = await query<[string][]>(`
      SELECT DISTINCT(
        SUBSTRING(state_note, 'key=(.*)')
      ) as bad_key
      FROM states
      WHERE state_name = '${HOST_KEY_CHANGED_PREFIX}${target}';`);

    badKeys = rows.map(([badKey]) => badKey);
  } catch (error) {
    return respond.s500(
      'd5a2acf',
      `Failed to list SSH key conflicts; CAUSE: ${error}`,
    );
  }

  if (badKeys.length > 0) {
    responseBody.badSshKeys = {
      badKeys: badKeys,
    };
  }

  return respond.s200(responseBody);
};
