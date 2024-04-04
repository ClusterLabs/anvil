import { RequestHandler } from 'express';

import { getAnvilData, getHostData } from '../../accessModule';
import { perr } from '../../shell';
import { buildAnvilSummary } from './buildAnvilSummary';

export const getAnvilDetail: RequestHandler<
  AnvilDetailParamsDictionary,
  AnvilDetailSummary,
  undefined
> = async (request, response) => {
  const {
    params: { anvilUuid },
  } = request;

  let anvils: AnvilDataAnvilListHash;
  let hosts: AnvilDataHostListHash;

  try {
    anvils = await getAnvilData();
    hosts = await getHostData();
  } catch (error) {
    perr(`Failed to get anvil and/or host data; CAUSE: ${error}`);

    return response.status(500).send();
  }

  let result: AnvilDetailSummary;

  try {
    result = await buildAnvilSummary({
      anvils,
      anvilUuid,
      hosts,
    });
  } catch (error) {
    perr(`Failed to get summary of anvil node ${anvilUuid}; CAUSE: ${error}`);

    return response.status(500).send();
  }

  response.status(200).send(result);
};
