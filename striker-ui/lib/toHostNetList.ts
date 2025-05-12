import { v4 as uuidv4 } from 'uuid';

const toHostNetList = (networks: APIHostNetworkList) =>
  Object.entries(networks).reduce<Record<string, HostNetFormikValues>>(
    (previous, [, value]) => {
      const {
        ip,
        link1Uuid,
        link2Uuid = '',
        sequence,
        subnetMask,
        type,
      } = value;

      let key: string;

      if (sequence === 1) {
        key = `default${type}`;
      } else {
        key = uuidv4();
      }

      previous[key] = {
        interfaces: [link1Uuid, link2Uuid],
        ip,
        sequence: String(sequence),
        subnetMask,
        type,
      };

      return previous;
    },
    {},
  );

export default toHostNetList;
