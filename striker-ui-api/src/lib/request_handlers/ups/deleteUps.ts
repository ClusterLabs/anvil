import { DELETED } from '../../consts';

import { write } from '../../accessModule';
import { buildDeleteRequestHandler } from '../buildDeleteRequestHandler';
import join from '../../join';

export const deleteUps = buildDeleteRequestHandler({
  delete: async (upsUuids) => {
    const wcode = await write(
      `UPDATE upses
        SET ups_ip_address = '${DELETED}'
        WHERE ups_uuid IN (${join(upsUuids, {
          elementWrapper: "'",
          separator: ',',
        })});`,
    );

    if (wcode !== 0) throw Error(`Write exited with code ${wcode}`);
  },
});
