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
  ).reduce<UPSTemplate>((previous, [upsTypeId, value]) => {
    const { brand, description: rawDescription, ...rest } = value;

    const matched = rawDescription.match(
      /^(.+)\s+[-]\s+[<][^>]+href=[\\"]+([^\s]+)[\\"]+.+[>]([^<]+)[<]/,
    );
    const result: UPSTemplate[string] = {
      ...rest,
      brand,
      description: rawDescription,
      links: {},
    };

    if (matched) {
      const [, description, linkHref, linkLabel] = matched;

      result.description = description;
      result.links[0] = { linkHref, linkLabel };
    }

    if (/apc/i.test(brand)) {
      previous[upsTypeId] = result;
    }

    return previous;
  }, {});

  response.status(200).send(upsData);
};
