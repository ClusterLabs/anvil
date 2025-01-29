import { RequestHandler } from 'express';

import { listNicModels } from '../../accessModule';
import { Responder } from '../../Responder';

type HostDetailParamsDictionary = {
  uuid: string;
};

type HostDetailNicModels = string[];

export const getHostNicModels: RequestHandler<
  HostDetailParamsDictionary,
  HostDetailNicModels
> = async (request, response) => {
  const respond = new Responder(response);

  const { uuid } = request.params;

  let nicModels: string[];

  try {
    nicModels = await listNicModels(uuid);
  } catch (error) {
    return respond.s500(
      '5e526c2',
      `Failed to get NIC model list for host ${uuid}; CAUSE: ${error}`,
    );
  }

  return respond.s200(nicModels);
};
