import { RequestHandler } from 'express';
import { getAnvilData } from '../../accessModule';
import { stderr } from '../../shell';

export const getFenceTemplate: RequestHandler = (request, response) => {
  let rawFenceData;

  try {
    ({ fence_data: rawFenceData } = getAnvilData(
      { fence_data: true },
      { predata: [['Striker->get_fence_data']] },
    ));
  } catch (subError) {
    stderr(`Failed to get fence device template; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  response.status(200).send(rawFenceData);
};
