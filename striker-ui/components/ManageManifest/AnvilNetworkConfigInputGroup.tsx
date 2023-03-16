import { ReactElement, useCallback, useMemo, useState } from 'react';
import { v4 as uuidv4 } from 'uuid';

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

const DEFAULT_NETWORKS: AnvilNetworkConfigNetworkList = {
  bcn1: {
    networkMinIp: '',
    networkNumber: 1,
    networkSubnetMask: '',
    networkType: 'bcn',
  },
  sn1: {
    networkMinIp: '',
    networkNumber: 1,
    networkSubnetMask: '',
    networkType: 'sn',
  },
  ifn1: {
    networkMinIp: '',
    networkNumber: 1,
    networkSubnetMask: '',
    networkType: 'ifn',
  },
};

const isIfn = (type: string) => type === 'ifn';

const AnvilNetworkConfigInputGroup = <
  M extends MapToInputTestID & {
    [K in
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_DNS
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_MTU
      | typeof INPUT_ID_ANVIL_NETWORK_CONFIG_NTP]: string;
  },
>({
  formUtils,
  previous: {
    dnsCsv: previousDnsCsv,
    mtu: previousMtu,
    networks: previousNetworks = DEFAULT_NETWORKS,
    ntpCsv: previousNtpCsv,
  } = {},
}: AnvilNetworkConfigInputGroupProps<M>): ReactElement => {
  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
  } = formUtils;

  const [networkList, setNetworkList] =
    useState<AnvilNetworkConfigNetworkList>(previousNetworks);

  const networkListArray = useMemo(
    () => Object.entries(networkList),
    [networkList],
  );

  const getNetworkNumber = useCallback(
    (
      type: string,
      {
        input = networkListArray,
        end = networkListArray.length,
      }: {
        input?: Array<[string, AnvilNetworkConfigNetwork]>;
        end?: number;
      } = {},
    ) => {
      let netNum = 0;

      input.every(([, { networkType }], networkIndex) => {
        if (networkType === type) {
          netNum += 1;
        }

        return networkIndex < end;
      });

      return netNum;
    },
    [networkListArray],
  );

  const buildNetwork = useCallback(
    ({
      networkMinIp = '',
      networkSubnetMask = '',
      networkType = 'ifn',
      // Params that depend on others.
      networkGateway = isIfn(networkType) ? '' : undefined,
      networkNumber = getNetworkNumber(networkType) + 1,
    }: Partial<AnvilNetworkConfigNetwork> = {}): {
      network: AnvilNetworkConfigNetwork;
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
    (key: string, value?: AnvilNetworkConfigNetwork) =>
      setNetworkList(buildObjectStateSetterCallback(key, value)),
    [],
  );

  const removeNetwork = useCallback<AnvilNetworkCloseHandler>(
    ({ networkId: rmId, networkType: rmType }) => {
      let isIdMatch = false;
      let networkNumber = 0;

      const newList = networkListArray.reduce<AnvilNetworkConfigNetworkList>(
        (previous, [networkId, networkValue]) => {
          const { networkType } = networkValue;

          if (networkId === rmId) {
            isIdMatch = true;
          } else {
            if (networkType === rmType) {
              networkNumber += 1;
            }

            if (isIdMatch) {
              previous[networkId] = {
                ...networkValue,
                networkNumber,
              };
            } else {
              previous[networkId] = networkValue;
            }
          }

          return previous;
        },
        {},
      );

      setNetworkList(newList);
    },
    [networkListArray],
  );

  const networksGridLayout = useMemo<GridLayout>(() => {
    let result: GridLayout = {};

    result = networkListArray.reduce<GridLayout>(
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
        const inputSubnetMaskId = `${inputIdPrefix}-subnet-mask`;

        const isFirstNetwork = networkNumber === 1;
        const isShowGateway = isIfn(networkType);

        previous[cellId] = {
          children: (
            <AnvilNetworkInputGroup
              formUtils={formUtils}
              idPrefix={idPrefix}
              inputGatewayId={inputGatewayId}
              inputMinIpId={inputMinIpId}
              inputSubnetMaskId={inputSubnetMaskId}
              networkId={networkId}
              networkNumber={networkNumber}
              networkType={networkType}
              onClose={removeNetwork}
              previous={{
                gateway: networkGateway,
                minIp: networkMinIp,
                subnetMask: networkSubnetMask,
              }}
              showCloseButton={!isFirstNetwork}
              showGateway={isShowGateway}
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
  }, [formUtils, networkListArray, removeNetwork]);

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
