import cloneDeep from 'lodash/cloneDeep';

const guessHostNets = <F extends HostNetInitFormikExtension>({
  appliedNics,
  chains,
  nics,
  formikUtils,
  host,
  subnodeCount = 2,
}: {
  appliedNics: Record<string, boolean>;
  chains: Record<'dns' | 'gateway' | 'networkInit' | 'networks', string>;
  nics: APINetworkInterfaceOverviewList;
  formikUtils: FormikUtils<F>;
  host: HostNetInitHost;
  subnodeCount?: number;
}) => {
  const { formik, getFieldChanged } = formikUtils;

  // Clone at the level that includes all possible changes.
  const clone = cloneDeep(formik.values.networkInit);

  // Get the host network slot values as readonly.
  const hostNets: ReadonlyArray<[string, HostNetFormikValues]> =
    Object.entries<HostNetFormikValues>(formik.values.networkInit.networks);

  // List unapplied interfaces.
  const unappliedNics = Object.values(nics).filter((nic) => {
    const { uuid } = nic;

    return !appliedNics[uuid];
  });

  // Put as many known interfaces into their previous slot(s) and return the
  // unused interfaces.
  const unknownNics = unappliedNics.filter((nic) => {
    const { slot: nicSlot } = nic;

    if (!nicSlot) {
      return true;
    }

    const found = hostNets.find((pair) => {
      const [, hostSlot] = pair;

      return (
        `${hostSlot.type}${hostSlot.sequence}` ===
        `${nicSlot.type}${nicSlot.sequence}`
      );
    });

    if (!found) {
      return true;
    }

    // At this point, we found a host slot for this NIC to fit in.

    const [key] = found;

    const slot = clone.networks[key];

    const initialParent: Readonly<HostNetInitFormikValues> =
      formik.initialValues.networkInit;
    const initialSlot: Readonly<HostNetFormikValues> | undefined =
      initialParent.networks[key];

    const linkIndex = nicSlot.link - 1;

    const netChain = `${chains.networks}.${key}`;
    const linkChain = `${netChain}.interfaces.${linkIndex}`;
    const ipChain = `${netChain}.ip`;
    const maskChain = `${netChain}.subnetMask`;

    if (!getFieldChanged(linkChain) && !initialSlot?.interfaces[linkIndex]) {
      slot.interfaces[linkIndex] = nic.uuid;
    }

    if (!getFieldChanged(ipChain) && !initialSlot?.ip) {
      slot.ip = nicSlot.ip || '';
    }

    if (!getFieldChanged(maskChain) && !initialSlot?.subnetMask) {
      slot.subnetMask = nicSlot.subnetMask || '';
    }

    if (!getFieldChanged(chains.dns) && !initialParent.dns) {
      clone.dns = nicSlot.dns || '';
    }

    if (!getFieldChanged(chains.gateway) && !initialParent.gateway) {
      clone.gateway = nicSlot.gateway || '';
    }

    return false;
  });

  // Categorize unknown interfaces based on their IP.
  const candidates = unknownNics.reduce<
    Record<'bcn' | 'ifn' | 'mn' | 'sn', APINetworkInterfaceOverview[]>
  >(
    (previous, nic) => {
      const { ip } = nic;

      if (!ip) {
        return previous;
      }

      if (/^10\.10/.test(ip)) {
        previous.sn.push(nic);
      } else if (/^10\.19/.test(ip)) {
        previous.mn.push(nic);
      } else if (/^10\.20/.test(ip)) {
        previous.bcn.push(nic);
      } else {
        previous.ifn.push(nic);
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
      bcn: 200,
      sn: 100,
    };

    slotTypes.forEach((slotType) => {
      let ipo3 = '??';

      if (host.type === 'striker') {
        ipo3 = '4';
      } else if (host.parentSequence > 0) {
        ipo3 = String(10 + subnodeCount * (host.parentSequence - 1));
      }

      slots[slotType].forEach(([key]) => {
        const slot = clone.networks[key];

        const initialSlot: Readonly<HostNetFormikValues> | undefined =
          formik.initialValues.networkInit.networks[key];

        const netChain = `${chains.networks}.${key}`;
        const ifChain = `${netChain}.interfaces.0`;
        const ipChain = `${netChain}.ip`;
        const maskChain = `${netChain}.subnetMask`;

        if (!getFieldChanged(ipChain) && !initialSlot?.ip) {
          const ipo2 =
            slotType === 'mn'
              ? 199
              : ipo2Prefixes[slotType] + Number(slot.sequence);

          let ipo4 = host.sequence;

          if (host.type === 'dr') {
            ipo4 += subnodeCount;
          }

          const ip = `10.${ipo2}.${ipo3}.${ipo4}`;

          slot.ip = ip;
        }

        if (!getFieldChanged(maskChain) && !initialSlot?.subnetMask) {
          slot.subnetMask = '255.255.0.0';
        }

        if (!getFieldChanged(ifChain) && !initialSlot?.interfaces[0]) {
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

  slots.ifn.forEach(([key]) => {
    const slot = clone.networks[key];

    const initialParent: Readonly<HostNetInitFormikValues> =
      formik.initialValues.networkInit;
    const initialSlot: Readonly<HostNetFormikValues> | undefined =
      initialParent.networks[key];

    const netChain = `${chains.networks}.${key}`;
    const ifChain = `${netChain}.interfaces.0`;
    const ipChain = `${netChain}.ip`;
    const maskChain = `${netChain}.subnetMask`;

    const candidate = candidates.ifn.shift();

    if (!candidate) {
      return;
    }

    if (!getFieldChanged(ifChain) && !initialSlot?.interfaces[0]) {
      slot.interfaces[0] = candidate.uuid;
    }

    if (!getFieldChanged(ipChain) && !initialSlot?.ip) {
      slot.ip = candidate.ip || '';
    }

    if (!getFieldChanged(maskChain) && !initialSlot?.subnetMask) {
      slot.subnetMask = candidate.subnetMask || '';
    }

    if (slot.sequence !== '1') {
      return;
    }

    if (!getFieldChanged(chains.dns) && !initialParent.dns) {
      clone.dns = candidate.dns || '';
    }

    if (!getFieldChanged(chains.gateway) && !initialParent.gateway) {
      clone.gateway = candidate.gateway || '';
    }
  });

  formik.setFieldValue(chains.networkInit, clone, true);
};

export default guessHostNets;
