import { cloneDeep } from 'lodash';
import { v4 as uuidv4 } from 'uuid';

const guessHostNets = <F extends HostNetInitFormikExtension>({
  appliedIfaces,
  chains,
  data,
  host,
  autoAddMn,
  formikUtils,
}: {
  appliedIfaces: Record<string, boolean>;
  chains: Record<'dns' | 'gateway' | 'networkInit' | 'networks', string>;
  data: APINetworkInterfaceOverviewList;
  host: HostNetInitHost;
  autoAddMn: React.MutableRefObject<boolean>;
  formikUtils: FormikUtils<F>;
}) => {
  const { formik, getFieldChanged } = formikUtils;

  // Clone at the level that includes all possible changes.
  const clone = cloneDeep(formik.values.networkInit);

  const ifaceValues = Object.values(data);

  if (autoAddMn.current && host.type === 'subnode' && ifaceValues.length >= 8) {
    const nyuId = uuidv4();

    clone.networks[nyuId] = {
      interfaces: ['', ''],
      ip: '',
      sequence: '1',
      subnetMask: '',
      type: 'mn',
    };

    autoAddMn.current = false;
  }

  // Categorize unapplied interfaces based on their IP.
  const candidates = ifaceValues.reduce<
    Record<'bcn' | 'ifn' | 'mn' | 'sn', APINetworkInterfaceOverview[]>
  >(
    (previous, iface) => {
      const { ip, uuid } = iface;

      if (appliedIfaces[uuid] || !ip) {
        return previous;
      }

      if (/^10\.10/.test(ip)) {
        previous.sn.push(iface);
      } else if (/^10\.19/.test(ip)) {
        previous.mn.push(iface);
      } else if (/^10\.20/.test(ip)) {
        previous.bcn.push(iface);
      } else {
        previous.ifn.push(iface);
      }

      return previous;
    },
    {
      bcn: [],
      ifn: [],
      mn: [],
      sn: [],
    },
  );

  const hostNets = Object.entries(formik.values.networkInit.networks);

  // Categorize slots based on their type.
  const slots = hostNets.reduce<
    Record<'bcn' | 'ifn' | 'mn' | 'sn', [string, HostNetFormikValues][]>
  >(
    (previous, pair) => {
      const [, slotValues] = pair;

      if (slotValues.type === 'bcn') {
        previous.bcn.push(pair);
      } else if (slotValues.type === 'ifn') {
        previous.ifn.push(pair);
      } else if (slotValues.type === 'mn') {
        previous.mn.push(pair);
      } else if (slotValues.type === 'sn') {
        previous.sn.push(pair);
      }

      return previous;
    },
    {
      bcn: [],
      ifn: [],
      mn: [],
      sn: [],
    },
  );

  if (host.sequence > 0) {
    const slotTypes: ['bcn', 'mn', 'sn'] = ['bcn', 'mn', 'sn'];

    const ipo2Prefixes = {
      bcn: '20',
      sn: '10',
    };

    slotTypes.forEach((slotType) => {
      let ipo3 = '??';

      if (host.type === 'striker') {
        ipo3 = '4';
      } else if (host.parentSequence) {
        ipo3 = String(10 + 2 * (host.parentSequence - 1));
      }

      slots[slotType].forEach(([key]) => {
        const slot = clone.networks[key];

        const netChain = `${chains.networks}.${key}`;
        const ifChain = `${netChain}.interfaces.0`;
        const ipChain = `${netChain}.ip`;
        const maskChain = `${netChain}.subnetMask`;

        if (!getFieldChanged(ipChain)) {
          const ipo2 =
            slotType === 'mn'
              ? '199'
              : `${ipo2Prefixes[slotType]}${slot.sequence}`;

          const ip = `10.${ipo2}.${ipo3}.${host.sequence}`;

          slot.ip = ip;
        }

        if (!getFieldChanged(maskChain)) {
          slot.subnetMask = '255.255.0.0';
        }

        if (!getFieldChanged(ifChain)) {
          const found = candidates[slotType].find(
            (value) => value.ip === slot.ip,
          );

          if (found) {
            slot.interfaces[0] = found.uuid;
          }
        }
      });
    });
  }

  // eslint-disable-next-line complexity
  slots.ifn.forEach(([key]) => {
    const slot = clone.networks[key];

    const netChain = `${chains.networks}.${key}`;
    const ifChain = `${netChain}.interfaces.0`;
    const ipChain = `${netChain}.ip`;
    const maskChain = `${netChain}.subnetMask`;

    const candidate = candidates.ifn.shift();

    if (!candidate) return;

    if (!getFieldChanged(ifChain)) {
      slot.interfaces[0] = candidate.uuid;
    }

    if (!getFieldChanged(ipChain)) {
      slot.ip = candidate.ip || '';
    }

    if (!getFieldChanged(maskChain)) {
      slot.subnetMask = candidate.subnetMask || '';
    }

    if (slot.sequence !== '1') return;

    if (!getFieldChanged(chains.dns)) {
      clone.dns = candidate.dns || '';
    }

    if (!getFieldChanged(chains.gateway)) {
      clone.gateway = candidate.gateway || '';
    }
  });

  formik.setFieldValue(chains.networkInit, clone, true);
};

export default guessHostNets;
