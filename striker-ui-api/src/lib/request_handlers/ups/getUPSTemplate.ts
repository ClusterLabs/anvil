import { RequestHandler } from 'express';

import { getAnvilData } from '../../accessModule';
import { stderr } from '../../shell';

export const getUPSTemplate: RequestHandler = (request, response) => {
  let rawUPSData;

  try {
    ({ ups_data: rawUPSData } = getAnvilData<{ ups_data: AnvilDataUPSHash }>(
      { ups_data: true },
      { predata: [['Striker->get_ups_data']] },
    ));
  } catch (subError) {
    stderr(`Failed to get ups template; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  response.status(200).send(rawUPSData);
};
