import { ReactElement, useCallback, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import AnvilNetworkInputGroup from './AnvilNetworkInputGroup';
import buildObjectStateSetterCallback from '../../lib/buildObjectStateSetterCallback';
import Grid from '../Grid';
import IconButton from '../IconButton';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { buildNumberTestBatch } from '../../lib/test_input';

const INPUT_ID_PREFIX_ANVIL_NETWORK_CONFIG = 'anvil-network-config-input';

const INPUT_CELL_ID_PREFIX_ANVIL_NETWORK_CONFIG = `${INPUT_ID_PREFIX_ANVIL_NETWORK_CONFIG}-cell`;

const INPUT_ID_ANVIL_NETWORK_CONFIG_DNS = 'anvil-network-config-input-dns';
const INPUT_ID_ANVIL_NETWORK_CONFIG_MTU = 'anvil-network-config-input-mtu';
const INPUT_ID_ANVIL_NETWORK_CONFIG_NTP = 'anvil-network-config-input-ntp';

const INPUT_LABEL_ANVIL_NETWORK_CONFIG_DNS = 'DNS';
const INPUT_LABEL_ANVIL_NETWORK_CONFIG_MTU = 'MTU';
const INPUT_LABEL_ANVIL_NETWORK_CONFIG_NTP = 'NTP';

const DEFAULT_DNS_CSV = '8.8.8.8, 8.8.4.4';

const NETWORK_TYPE_ENTRIES = Object.entries(NETWORK_TYPES);

const assertIfn = (type: string) => type === 'ifn';
const assertMn = (type: string) => type === 'mn';

const AnvilNetworkConfigInputGroup = <
  M extends MapToInputTestID & {
    [K in
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_DNS
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_MTU
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_NTP]: string;
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
}: AnvilNetworkConfigInputGroupProps<M>): ReactElement => {
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

  const handleNetworkTypeChange =
    useCallback<AnvilNetworkTypeChangeEventHandler>(
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

  const handleNetworkRemove = useCallback<AnvilNetworkCloseEventHandler>(
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
        const cellId = `${INPUT_CELL_ID_PREFIX_ANVIL_NETWORK_CONFIG}-${networkId}`;

        const idPrefix = `anvil-network-${networkId}`;

        const inputIdPrefix = `${INPUT_ID_PREFIX_ANVIL_NETWORK_CONFIG}-${networkId}`;
        const inputGatewayId = `${inputIdPrefix}-gateway`;
        const inputMinIpId = `${inputIdPrefix}-min-ip`;
        const inputNetworkTypeId = `${inputIdPrefix}-network-type`;
        const inputSubnetMaskId = `${inputIdPrefix}-subnet-mask`;

        const isFirstNetwork = networkNumber === 1;
        const isIfn = assertIfn(networkType);
        const isMn = assertMn(networkType);
        const isOptional = isMn || !isFirstNetwork;

        previous[cellId] = {
          children: (
            <AnvilNetworkInputGroup
              formUtils={formUtils}
              idPrefix={idPrefix}
              inputGatewayId={inputGatewayId}
              inputMinIpId={inputMinIpId}
              inputNetworkTypeId={inputNetworkTypeId}
              inputSubnetMaskId={inputSubnetMaskId}
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
        'anvil-network-config-cell-add-network': {
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
        'anvil-network-config-input-cell-dns': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_ANVIL_NETWORK_CONFIG_DNS}
                  label={INPUT_LABEL_ANVIL_NETWORK_CONFIG_DNS}
                  value={previousDnsCsv}
                />
              }
              required
            />
          ),
        },
        'anvil-network-config-input-cell-ntp': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_ANVIL_NETWORK_CONFIG_NTP}
                  label={INPUT_LABEL_ANVIL_NETWORK_CONFIG_NTP}
                  value={previousNtpCsv}
                />
              }
            />
          ),
        },
        'anvil-network-config-input-cell-mtu': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_ANVIL_NETWORK_CONFIG_MTU}
                  inputProps={{ placeholder: '1500' }}
                  label={INPUT_LABEL_ANVIL_NETWORK_CONFIG_MTU}
                  value={previousMtu}
                />
              }
              inputTestBatch={buildNumberTestBatch(
                INPUT_LABEL_ANVIL_NETWORK_CONFIG_MTU,
                () => {
                  msgSetters[INPUT_ID_ANVIL_NETWORK_CONFIG_MTU]();
                },
                {
                  onFinishBatch: buildFinishInputTestBatchFunction(
                    INPUT_ID_ANVIL_NETWORK_CONFIG_MTU,
                  ),
                },
                (message) => {
                  msgSetters[INPUT_ID_ANVIL_NETWORK_CONFIG_MTU]({
                    children: message,
                  });
                },
              )}
              onFirstRender={buildInputFirstRenderFunction(
                INPUT_ID_ANVIL_NETWORK_CONFIG_MTU,
              )}
              valueType="number"
            />
          ),
        },
      }}
      spacing="1em"
    />
  );
};

export {
  INPUT_ID_ANVIL_NETWORK_CONFIG_DNS,
  INPUT_ID_ANVIL_NETWORK_CONFIG_MTU,
  INPUT_ID_ANVIL_NETWORK_CONFIG_NTP,
};

export default AnvilNetworkConfigInputGroup;
