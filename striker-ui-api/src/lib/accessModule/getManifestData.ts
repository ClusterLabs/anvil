import { getData } from './getData';
import { sub } from './sub';

export const getManifestData = async (manifestUuid?: string) => {
  await sub('load_manifest', {
    params: [{ manifest_uuid: manifestUuid }],
    pre: ['Striker'],
  });

  return getData<AnvilDataManifestListHash>('manifests');
};
