import { Netmask } from 'netmask';
import { ReactElement, useCallback, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import AnNetworkInputGroup from './AnNetworkInputGroup';
import buildObjectStateSetterCallback from '../../lib/buildObjectStateSetterCallback';
import Grid from '../Grid';
import IconButton from '../IconButton';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { buildIpCsvTestBatch } from '../../lib/test_input';

const INPUT_ID_PREFIX_AN_NETWORK_CONFIG = 'an-network-config-input';

const INPUT_CELL_ID_PREFIX_ANC = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-cell`;

const INPUT_ID_ANC_DNS = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-dns`;
const INPUT_ID_ANC_NTP = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-ntp`;

const INPUT_LABEL_ANC_DNS = 'DNS';
const INPUT_LABEL_ANC_NTP = 'NTP';

const DEFAULT_DNS_CSV = '8.8.8.8,8.8.4.4';

const NETWORK_TYPE_ENTRIES = Object.entries(NETWORK_TYPES);

const MAP_TO_NETWORK_DEFAULTS: Record<string, { base: string; mask: string }> =
  {
    bcn: { base: '10.201.0.0', mask: '255.255.0.0' },
    mn: { base: '10.199.0.0', mask: '255.255.0.0' },
    sn: { base: '10.101.0.0', mask: '255.255.0.0' },
  };

const assertIfn = (type: string) => type === 'ifn';
const assertMn = (type: string) => type === 'mn';

const guessNetworkMinIp = ({
  entries,
  type,
}: {
  entries: [string, ManifestNetwork][];
  type: string;
}): { base?: string; mask?: string } => {
  const last = entries
    .filter(([, { networkType }]) => networkType === type)
    .sort(([, { networkNumber: a }], [, { networkNumber: b }]) =>
      a > b ? 1 : -1,
    )
    .pop();

  if (!last) {
    return MAP_TO_NETWORK_DEFAULTS[type] ?? {};
  }

  const [, { networkMinIp, networkSubnetMask }] = last;

  try {
    const block = new Netmask(`${networkMinIp}/${networkSubnetMask}`);
    const { base, mask } = block.next();

    return { base, mask };
  } catch (error) {
    return {};
  }
};

const AnNetworkConfigInputGroup = <
  M extends MapToInputTestID & {
    [K in typeof INPUT_ID_ANC_DNS | typeof INPUT_ID_ANC_NTP]: string;
  },
>({
  formUtils,
  networkListEntries,
  previous: {
    dnsCsv: previousDnsCsv = DEFAULT_DNS_CSV,
    ntpCsv: previousNtpCsv,
  } = {},
  setNetworkList,
}: AnNetworkConfigInputGroupProps<M>): ReactElement => {
  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMessage,
    setMessageRe,
  } = formUtils;

  const getNetworkNumber = useCallback(
    (
      type: string,
      {
        input = networkListEntries,
        end = networkListEntries.length,
      }: {
        input?: Array<[string, ManifestNetwork]>;
        end?: number;
      } = {},
    ) => {
      const limit = end - 1;

      let netNum = 0;

      input.every(([, { networkType }], networkIndex) => {
        if (networkType === type) {
          netNum += 1;
        }

        return networkIndex < limit;
      });

      return netNum;
    },
    [networkListEntries],
  );

  const networkTypeOptions = useMemo<SelectItem[]>(
    () =>
      NETWORK_TYPE_ENTRIES.map(([key, value]) => ({
        displayValue: value,
        value: key,
      })),
    [],
  );

  const buildNetwork = useCallback(
    ({
      networkMinIp = '',
      networkSubnetMask = '',
      networkType = networkListEntries.some(([, { networkType: nt }]) =>
        assertMn(nt),
      )
        ? 'ifn'
        : 'mn',
      // Params that depend on others.
      networkGateway = assertIfn(networkType) ? '' : undefined,
      networkNumber = getNetworkNumber(networkType) + 1,
    }: Partial<ManifestNetwork> = {}): {
      network: ManifestNetwork;
      networkId: string;
    } => {
      const { base = networkMinIp, mask = networkSubnetMask } =
        guessNetworkMinIp({
          entries: networkListEntries,
          type: networkType,
        });

      return {
        network: {
          networkGateway,
          networkMinIp: base,
          networkNumber,
          networkSubnetMask: mask,
          networkType,
        },
        networkId: uuidv4(),
      };
    },
    [getNetworkNumber, networkListEntries],
  );

  const setNetwork = useCallback(
    (key: string, value?: ManifestNetwork) =>
      setNetworkList(buildObjectStateSetterCallback(key, value)),
    [setNetworkList],
  );

  const setNetworkProp = useCallback(
    <P extends keyof ManifestNetwork>(
      nkey: string,
      pkey: P,
      value: ManifestNetwork[P],
    ) =>
      setNetworkList((previous) => {
        const nyu = { ...previous };

        const { [nkey]: nw } = nyu;

        if (nw) {
          nw[pkey] = value;
        }

        return nyu;
      }),
    [setNetworkList],
  );

  const handleNetworkTypeChange = useCallback<AnNetworkTypeChangeEventHandler>(
    (
      { networkId: targetId, networkType: previousType },
      { target: { value } },
    ) => {
      const newType = String(value);

      let isIdMatch = false;
      let newTypeNumber = 0;

      const newList = networkListEntries.reduce<ManifestNetworkList>(
        (previous, [networkId, networkValue]) => {
          const {
            networkNumber: initnn,
            networkType: initnt,
            networkMinIp: initbase,
            networkSubnetMask: initmask,
            ...restNetworkValue
          } = networkValue;

          let networkNumber = initnn;
          let networkType = initnt;

          if (networkId === targetId) {
            isIdMatch = true;
            networkType = newType;
            setMessageRe(RegExp(networkId));
          }

          const isTypeMatch = networkType === newType;

          if (isTypeMatch) {
            newTypeNumber += 1;
          }

          if (isIdMatch) {
            if (isTypeMatch) {
              networkNumber = newTypeNumber;
            } else if (networkType === previousType) {
              networkNumber -= 1;
            }

            const {
              base: networkMinIp = initbase,
              mask: networkSubnetMask = initmask,
            } = guessNetworkMinIp({
              entries: networkListEntries,
              type: networkType,
            });

            previous[networkId] = {
              ...restNetworkValue,
              networkMinIp,
              networkSubnetMask,
              networkNumber,
              networkType,
            };
          } else {
            previous[networkId] = networkValue;
          }

          return previous;
        },
        {},
      );

      setNetworkList(newList);
    },
    [networkListEntries, setMessageRe, setNetworkList],
  );

  const handleNetworkRemove = useCallback<AnNetworkCloseEventHandler>(
    ({ networkId: rmId, networkType: rmType }) => {
      let postMatch = false;
      let networkNumber = 0;

      const newList = networkListEntries.reduce<ManifestNetworkList>(
        (previous, [networkId, networkValue]) => {
          if (networkId === rmId) {
            postMatch = true;

            return previous;
          }

          const { networkType } = networkValue;

          const change = networkType === rmType;

          if (change) {
            networkNumber += 1;
          }

          previous[networkId] =
            postMatch && change
              ? { ...networkValue, networkNumber }
              : networkValue;

          return previous;
        },
        {},
      );

      setNetworkList(newList);
    },
    [networkListEntries, setNetworkList],
  );

  const networksGridLayout = useMemo<GridLayout>(() => {
    let result: GridLayout = {};

    result = networkListEntries.reduce<GridLayout>(
      (
        previous,
        [
          networkId,
          {
            networkGateway,
            networkMinIp,
            networkNumber,
            networkSubnetMask,
            networkType,
          },
        ],
      ) => {
        const cellId = `${INPUT_CELL_ID_PREFIX_ANC}-${networkId}`;

        const isFirstNetwork = networkNumber === 1;
        const isIfn = assertIfn(networkType);
        const isMn = assertMn(networkType);
        const isOptional = isMn || !isFirstNetwork;

        previous[cellId] = {
          children: (
            <AnNetworkInputGroup
              formUtils={formUtils}
              networkId={networkId}
              networkNumber={networkNumber}
              networkType={networkType}
              networkTypeOptions={networkTypeOptions}
              onClose={handleNetworkRemove}
              onNetworkMinIpChange={(
                { networkId: nid },
                { target: { value } },
              ) => setNetworkProp(nid, 'networkMinIp', value)}
              onNetworkSubnetMaskChange={(
                { networkId: nid },
                { target: { value } },
              ) => setNetworkProp(nid, 'networkSubnetMask', value)}
              onNetworkTypeChange={handleNetworkTypeChange}
              previous={{
                gateway: networkGateway,
                minIp: networkMinIp,
                subnetMask: networkSubnetMask,
              }}
              readonlyNetworkName={!isOptional}
              showCloseButton={isOptional}
              showGateway={isIfn}
            />
          ),
          md: 3,
          sm: 2,
        };

        return previous;
      },
      result,
    );

    return result;
  }, [
    networkListEntries,
    formUtils,
    networkTypeOptions,
    handleNetworkRemove,
    handleNetworkTypeChange,
    setNetworkProp,
  ]);

  return (
    <Grid
      columns={{ xs: 1, sm: 2, md: 3 }}
      layout={{
        ...networksGridLayout,
        'an-network-config-cell-add-network': {
          children: (
            <IconButton
              mapPreset="add"
              onClick={() => {
                const { network: newNet, networkId: newNetId } = buildNetwork();

                setNetwork(newNetId, newNet);
              }}
            />
          ),
          display: 'flex',
          justifyContent: 'center',
          md: 3,
          sm: 2,
        },
        'an-network-config-input-cell-dns': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_ANC_DNS}
                  label={INPUT_LABEL_ANC_DNS}
                  value={previousDnsCsv}
                />
              }
              inputTestBatch={buildIpCsvTestBatch(
                INPUT_LABEL_ANC_DNS,
                () => {
                  setMessage(INPUT_ID_ANC_DNS);
                },
                {
                  onFinishBatch:
                    buildFinishInputTestBatchFunction(INPUT_ID_ANC_DNS),
                },
                (message) => {
                  setMessage(INPUT_ID_ANC_DNS, { children: message });
                },
              )}
              onFirstRender={buildInputFirstRenderFunction(INPUT_ID_ANC_DNS)}
              required
            />
          ),
        },
        'an-network-config-input-cell-ntp': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_ANC_NTP}
                  label={INPUT_LABEL_ANC_NTP}
                  value={previousNtpCsv}
                />
              }
              inputTestBatch={buildIpCsvTestBatch(
                INPUT_LABEL_ANC_NTP,
                () => {
                  setMessage(INPUT_ID_ANC_NTP);
                },
                {
                  onFinishBatch:
                    buildFinishInputTestBatchFunction(INPUT_ID_ANC_NTP),
                },
                (message) => {
                  setMessage(INPUT_ID_ANC_NTP, { children: message });
                },
              )}
              onFirstRender={buildInputFirstRenderFunction(INPUT_ID_ANC_NTP)}
            />
          ),
        },
      }}
      spacing="1em"
    />
  );
};

export { INPUT_ID_ANC_DNS, INPUT_ID_ANC_NTP };

export default AnNetworkConfigInputGroup;
