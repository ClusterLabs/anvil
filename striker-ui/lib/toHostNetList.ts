import { v4 as uuidv4 } from 'uuid';

const toHostNetList = (networks: APIHostNetworkList) =>
  Object.entries(networks).reduce<Record<string, HostNetFormikValues>>(
    (previous, [nid, value]) => {
      const { ip, link1Uuid, link2Uuid = '', subnetMask, type } = value;

      const sequence = nid.replace(/^.*(\d+)$/, '$1');

      const key = sequence === '1' ? `default${type}` : uuidv4();

      previous[key] = {
        interfaces: [link1Uuid, link2Uuid],
        ip,
        sequence,
        subnetMask,
        type,
      };

      return previous;
    },
    {},
  );

export default toHostNetList;
