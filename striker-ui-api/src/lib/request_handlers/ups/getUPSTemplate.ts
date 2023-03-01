import { RequestHandler } from 'express';

import { getAnvilData } from '../../accessModule';
import { stderr } from '../../shell';

export const getUPSTemplate: RequestHandler = (request, response) => {
  let rawUPSData: AnvilDataUPSHash;

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

  const upsData: AnvilDataUPSHash = Object.entries(
    rawUPSData,
  ).reduce<AnvilDataUPSHash>((previous, [upsTypeId, value]) => {
    const { brand } = value;

    if (/apc/i.test(brand)) {
      previous[upsTypeId] = value;
    }

    return previous;
  }, {});

  response.status(200).send(upsData);
};
