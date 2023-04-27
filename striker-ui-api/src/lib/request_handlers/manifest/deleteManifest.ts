import { RequestHandler } from 'express';

import { sub } from '../../accessModule';
import { stderr, stdout } from '../../shell';

export const deleteManifest: RequestHandler<
  { manifestUuid: string },
  undefined,
  { uuids: string[] }
> = async (request, response) => {
  const {
    params: { manifestUuid: rawManifestUuid },
    body: { uuids: rawManifestUuidList } = {},
  } = request;

  const manifestUuidList: string[] = rawManifestUuidList
    ? rawManifestUuidList
    : [rawManifestUuid];

  for (const uuid of manifestUuidList) {
    stdout(`Begin delete manifest ${uuid}.`);

    try {
      await sub('insert_or_update_manifests', {
        params: [{ delete: 1, manifest_uuid: uuid }],
      });
    } catch (subError) {
      stderr(`Failed to delete manifest ${uuid}; CAUSE: ${subError}`);

      return response.status(500).send();
    }
  }

  response.status(204).send();
};
