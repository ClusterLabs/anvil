import { RequestHandler } from 'express';

import { getAnvilData } from '../../accessModule';
import { buildAnvilSummary } from './buildAnvilSummary';
import { perr } from '../../shell';

export const getAnvilSummary: RequestHandler<unknown, AnvilSummary> = async (
  request,
  response,
) => {
  let anvils: AnvilDataAnvilListHash;

  try {
    anvils = await getAnvilData();
  } catch (error) {
    perr(`Failed to get anvil and/or host data; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const { anvil_uuid: listByUuid } = anvils;
  const result: AnvilSummary = { anvils: [] };

  try {
    const entries = Object.entries(listByUuid);

    entries.sort(([, a], [, b]) => {
      const collator = new Intl.Collator(undefined, {
        numeric: true,
        sensitivity: 'accent',
      });

      return collator.compare(a.anvil_name, b.anvil_name);
    });

    for (const [uuid] of entries) {
      const anvil = await buildAnvilSummary({
        anvils,
        anvilUuid: uuid,
      });

      result.anvils.push(anvil);
    }
  } catch (error) {
    perr(`Failed to get summary of anvil nodes; CAUSE: ${error}`);

    return response.status(500).send();
  }

  response.json(result);
};
