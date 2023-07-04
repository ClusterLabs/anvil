import { DELETED } from '../../consts';

import { write } from '../../accessModule';
import { buildDeleteRequestHandler } from '../buildDeleteRequestHandler';
import join from '../../join';

export const deleteFence = buildDeleteRequestHandler({
  delete: async (fenceUuids) => {
    const wcode = await write(
      `UPDATE fences
        SET fence_arguments = '${DELETED}'
        WHERE fence_uuid IN (${join(fenceUuids, {
          elementWrapper: "'",
          separator: ',',
        })});`,
    );

    if (wcode !== 0) throw Error(`Write exited with code ${wcode}`);
  },
});
