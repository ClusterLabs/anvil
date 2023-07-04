import { RequestHandler } from 'express';

import { getFenceSpec } from '../../accessModule';
import { stderr } from '../../shell';

export const getFenceTemplate: RequestHandler = async (request, response) => {
  let rFenceData: AnvilDataFenceHash;

  try {
    rFenceData = await getFenceSpec();
  } catch (subError) {
    stderr(`Failed to get fence device template; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  response.status(200).send(rFenceData);
};
