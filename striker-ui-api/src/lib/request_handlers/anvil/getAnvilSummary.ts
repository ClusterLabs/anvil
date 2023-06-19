import { RequestHandler } from 'express';

import { getAnvilData, getHostData } from '../../accessModule';
import { buildAnvilSummary } from './buildAnvilSummary';
import { stderr } from '../../shell';

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
    stderr(`Failed to get anvil and/or host data; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const { anvil_uuid: alist } = anvils;
  const result: AnvilSummary = { anvils: [] };

  for (const auuid of Object.keys(alist)) {
    result.anvils.push(
      await buildAnvilSummary({ anvils, anvilUuid: auuid, hosts }),
    );
  }

  response.json(result);
};
