import { opGetData } from './getData';
import { getHostData } from './getHostData';
import { access } from './instance';
import { opSub } from './sub';

export const getNetworkData = async (
  hostUuid: string,
  hostName?: string,
): Promise<AnvilDataNetworkListHash> => {
  let replacementKey = hostName;

  if (!replacementKey) {
    ({
      host_uuid: {
        [hostUuid]: { short_host_name: replacementKey },
      },
    } = await getHostData());
  }

  const [
    ,
    {
      sub_results: [result],
    },
  ] = await access.default.interact<
    [null, SubroutineOutputWrapper<[AnvilDataNetworkListHash]>]
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
