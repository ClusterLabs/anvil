import { RequestHandler } from 'express';

import { listNicModels } from '../../accessModule';
import { Responder } from '../../Responder';

type HostNicModels = string[];

export const getHostNicModels: RequestHandler<
  Express.RhParamsDictionary,
  HostNicModels,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const hostUuid = response.locals.target.uuid;

  let nicModels: string[];

  try {
    nicModels = await listNicModels(hostUuid);
  } catch (error) {
    return respond.s500(
      '5e526c2',
      `Failed to get NIC model list for host ${hostUuid}; CAUSE: ${error}`,
    );
  }

  return respond.s200(nicModels);
};
