import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getManifestData = async (manifestUuid?: string) => {
  const [, result] = await access.default.interact<
    [null, AnvilDataManifestListHash]
  >(
    opSub('load_manifest', {
      params: [
        {
          manifest_uuid: manifestUuid,
        },
      ],
      pre: ['Striker'],
    }),
    opGetData('manifests'),
  );

  return result;
};
