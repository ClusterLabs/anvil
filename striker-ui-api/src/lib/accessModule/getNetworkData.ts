import { opGetData } from './getData';
import { getHostData } from './getHostData';
import { access } from './instance';
import { opSub } from './sub';

export const getNetworkData = async (hostUuid: string, hostName?: string) => {
  let replacementKey = hostName;

  if (!replacementKey) {
    ({
      host_uuid: {
        [hostUuid]: { short_host_name: replacementKey },
      },
    } = await getHostData());
  }

  const [, result] = await access.default.interact<
    [null, AnvilDataNetworkListHash]
  >(
    opSub('load_interfaces', {
      params: [
        {
          host: replacementKey,
          host_uuid: hostUuid,
        },
      ],
      pre: ['Network'],
    }),
    opGetData('network'),
  );

  return result;
};
