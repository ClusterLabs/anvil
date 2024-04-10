import { RequestHandler } from 'express';

import { getUpsSpec } from '../../accessModule';
import { perr } from '../../shell';

export const getUPSTemplate: RequestHandler = async (request, response) => {
  let rawUPSData: AnvilDataUPSHash;

  try {
    rawUPSData = await getUpsSpec();
  } catch (subError) {
    perr(`Failed to get ups template; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  const upsData: AnvilDataUPSHash = Object.entries(
    rawUPSData,
  ).reduce<UpsTemplate>((previous, [upsTypeId, value]) => {
    const { brand, description: rawDescription, ...rest } = value;

    const matched = rawDescription.match(
      /^(.+)\s+[-]\s+[<][^>]+href=[\\"]+([^\s]+)[\\"]+.+[>]([^<]+)[<]/,
    );
    const result: UpsTemplate[string] = {
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
