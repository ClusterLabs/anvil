import { RequestHandler } from 'express';

import { getAnvilData, getHostData } from '../../accessModule';
import { buildAnvilSummary } from './buildAnvilSummary';
import { perr } from '../../shell';

export const getAnvilSummary: RequestHandler<unknown, AnvilSummary> = async (
  request,
  response,
) => {
  let anvils: AnvilDataAnvilListHash;
  let hosts: AnvilDataHostListHash;

  try {
    anvils = await getAnvilData();
    hosts = await getHostData();
  } catch (error) {
    perr(`Failed to get anvil and/or host data; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const { anvil_uuid: alist } = anvils;
  const result: AnvilSummary = { anvils: [] };

  try {
    for (const auuid of Object.keys(alist)) {
      result.anvils.push(
        await buildAnvilSummary({ anvils, anvilUuid: auuid, hosts }),
      );
    }
  } catch (error) {
    perr(`Failed to get summary of anvil nodes; CAUSE: ${error}`);

    return response.status(500).send();
  }

  response.json(result);
};
