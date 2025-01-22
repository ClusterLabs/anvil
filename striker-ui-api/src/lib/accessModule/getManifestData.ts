import { opGetData } from './getData';
import { access } from './instance';
import { opSub } from './sub';

export const getManifestData = async (
  manifestUuid?: string,
): Promise<AnvilDataManifestListHash> => {
  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataManifestListHash]>]
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
