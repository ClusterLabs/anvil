import { ReactElement, useCallback, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import AnNetworkInputGroup from './AnNetworkInputGroup';
import buildObjectStateSetterCallback from '../../lib/buildObjectStateSetterCallback';
import Grid from '../Grid';
import IconButton from '../IconButton';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { buildNumberTestBatch } from '../../lib/test_input';

const INPUT_ID_PREFIX_AN_NETWORK_CONFIG = 'an-network-config-input';

const INPUT_CELL_ID_PREFIX_ANC = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-cell`;

const INPUT_ID_ANC_DNS = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-dns`;
const INPUT_ID_ANC_MTU = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-mtu`;
const INPUT_ID_ANC_NTP = `${INPUT_ID_PREFIX_AN_NETWORK_CONFIG}-ntp`;

const INPUT_LABEL_ANC_DNS = 'DNS';
const INPUT_LABEL_ANC_MTU = 'MTU';
const INPUT_LABEL_ANC_NTP = 'NTP';

const DEFAULT_DNS_CSV = '8.8.8.8,8.8.4.4';

const NETWORK_TYPE_ENTRIES = Object.entries(NETWORK_TYPES);

const assertIfn = (type: string) => type === 'ifn';
const assertMn = (type: string) => type === 'mn';

const AnNetworkConfigInputGroup = <
  M extends MapToInputTestID & {
    [K in
      | typeof INPUT_ID_ANC_DNS
      | typeof INPUT_ID_ANC_MTU
      | typeof INPUT_ID_ANC_NTP]: string;
  },
>({
  formUtils,
  networkListEntries,
  previous: {
    dnsCsv: previousDnsCsv = DEFAULT_DNS_CSV,
    mtu: previousMtu,
    ntpCsv: previousNtpCsv,
  } = {},
  setNetworkList,
}: AnNetworkConfigInputGroupProps<M>): ReactElement => {
  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
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
      networkType = 'ifn',
      // Params that depend on others.
      networkGateway = assertIfn(networkType) ? '' : undefined,
      networkNumber = getNetworkNumber(networkType) + 1,
    }: Partial<ManifestNetwork> = {}): {
      network: ManifestNetwork;
      networkId: string;
    } => ({
      network: {
        networkGateway,
        networkMinIp,
        networkNumber,
        networkSubnetMask,
        networkType,
      },
      networkId: uuidv4(),
    }),
    [getNetworkNumber],
  );

  const setNetwork = useCallback(
    (key: string, value?: ManifestNetwork) =>
      setNetworkList(buildObjectStateSetterCallback(key, value)),
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
          const { networkNumber: initnn, networkType: initnt } = networkValue;

          let networkNumber = initnn;
          let networkType = initnt;

          if (networkId === targetId) {
            isIdMatch = true;

            networkType = newType;
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

            previous[networkId] = {
              ...networkValue,
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
    [networkListEntries, setNetworkList],
  );

  const handleNetworkRemove = useCallback<AnNetworkCloseEventHandler>(
    ({ networkId: rmId, networkType: rmType }) => {
      let isIdMatch = false;
      let networkNumber = 0;

      const newList = networkListEntries.reduce<ManifestNetworkList>(
        (previous, [networkId, networkValue]) => {
          if (networkId === rmId) {
            isIdMatch = true;
          } else {
            const { networkType } = networkValue;

            if (networkType === rmType) {
              networkNumber += 1;
            }

            previous[networkId] = isIdMatch
              ? { ...networkValue, networkNumber }
              : networkValue;
          }

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
    formUtils,
    networkListEntries,
    networkTypeOptions,
    handleNetworkRemove,
    handleNetworkTypeChange,
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
            />
          ),
        },
        'an-network-config-input-cell-mtu': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_ANC_MTU}
                  inputProps={{ placeholder: '1500' }}
                  label={INPUT_LABEL_ANC_MTU}
                  value={previousMtu}
                />
              }
              inputTestBatch={buildNumberTestBatch(
                INPUT_LABEL_ANC_MTU,
                () => {
                  msgSetters[INPUT_ID_ANC_MTU]();
                },
                {
                  onFinishBatch:
                    buildFinishInputTestBatchFunction(INPUT_ID_ANC_MTU),
                },
                (message) => {
                  msgSetters[INPUT_ID_ANC_MTU]({
                    children: message,
                  });
                },
              )}
              onFirstRender={buildInputFirstRenderFunction(INPUT_ID_ANC_MTU)}
              valueType="number"
            />
          ),
        },
      }}
      spacing="1em"
    />
  );
};

export { INPUT_ID_ANC_DNS, INPUT_ID_ANC_MTU, INPUT_ID_ANC_NTP };

export default AnNetworkConfigInputGroup;
