import { RequestHandler } from 'express';

import { sub } from '../../accessModule';
import { stderr, stdout } from '../../shell';

export const deleteManifest: RequestHandler<
  { manifestUuid: string },
  undefined,
  { uuids: string[] }
> = (request, response) => {
  const {
    params: { manifestUuid: rawManifestUuid },
    body: { uuids: rawManifestUuidList } = {},
  } = request;

  const manifestUuidList: string[] = rawManifestUuidList
    ? rawManifestUuidList
    : [rawManifestUuid];

  manifestUuidList.forEach((uuid) => {
    stdout(`Begin delete manifest ${uuid}.`);

    try {
      sub('insert_or_update_manifests', {
        subParams: { delete: 1, manifest_uuid: uuid },
      });
    } catch (subError) {
      stderr(`Failed to delete manifest ${uuid}; CAUSE: ${subError}`);

      response.status(500).send();

      return;
    }
  });

  response.status(204).send();
};
