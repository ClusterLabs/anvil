import { getData } from './getData';
import { getHostData } from './getHostData';
import { sub } from './sub';

export const getNetworkData = async (hostUuid: string, hostName?: string) => {
  let replacementKey = hostName;

  if (!replacementKey) {
    ({
      host_uuid: {
        [hostUuid]: { short_host_name: replacementKey },
      },
    } = await getHostData());
  }

  await sub('load_interfaces', {
    params: [{ host: replacementKey, host_uuid: hostUuid }],
    pre: ['Network'],
  });

  return getData<AnvilDataNetworkListHash>('network');
};
