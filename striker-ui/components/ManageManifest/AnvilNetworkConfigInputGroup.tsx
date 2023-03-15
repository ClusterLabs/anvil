import { ReactElement, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import AnvilNetworkInputGroup from './AnvilNetworkInputGroup';
import Grid from '../Grid';
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

const DEFAULT_NETWORKS: { [networkId: string]: AnvilNetworkConfigNetwork } = {
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
    networks = DEFAULT_NETWORKS,
    ntpCsv: previousNtpCsv,
  } = {},
}: AnvilNetworkConfigInputGroupProps<M>): ReactElement => {
  const {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
  } = formUtils;

  const networksGridLayout = useMemo<GridLayout>(() => {
    let result: GridLayout = {};

    result = Object.entries(networks).reduce<GridLayout>(
      (
        previous,
        [
          networkId,
          {
            networkGateway: previousGateway,
            networkMinIp: previousMinIp,
            networkNumber,
            networkSubnetMask: previousSubnetMask,
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

        const networkName = `${NETWORK_TYPES[networkType]} ${networkNumber}`;

        const isShowGateway = networkType === 'ifn';

        previous[cellId] = {
          children: (
            <AnvilNetworkInputGroup
              formUtils={formUtils}
              idPrefix={idPrefix}
              inputGatewayId={inputGatewayId}
              inputMinIpId={inputMinIpId}
              inputSubnetMaskId={inputSubnetMaskId}
              networkName={networkName}
              previous={{
                gateway: previousGateway,
                minIp: previousMinIp,
                subnetMask: previousSubnetMask,
              }}
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
  }, [formUtils, networks]);

  return (
    <Grid
      columns={{ xs: 1, sm: 2, md: 3 }}
      layout={{
        ...networksGridLayout,
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
