import { debounce } from 'lodash';
import {  ReactNode, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import Grid from '../Grid';
import IconButton from '../IconButton';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import { buildIPAddressTestBatch } from '../../lib/test_input';

const INPUT_ID_PREFIX_AN_NETWORK = 'an-network-input';

const INPUT_CELL_ID_PREFIX_AN = `${INPUT_ID_PREFIX_AN_NETWORK}-cell`;

const MAP_TO_AN_INPUT_HANDLER: MapToManifestFormInputHandler = {
  gateway: (container, input) => {
    const {
      dataset: { networkId = '' },
      value,
    } = input;
    const {
      networkConfig: { networks },
    } = container;

    networks[networkId].networkGateway = value;
  },
  minip: (container, input) => {
    const {
      dataset: { networkId = '' },
      value,
    } = input;
    const {
      networkConfig: { networks },
    } = container;

    networks[networkId].networkMinIp = value;
  },
  network: (container, input) => {
    const {
      dataset: { networkId = '', networkNumber: rawNn = '', networkType = '' },
    } = input;
    const {
      networkConfig: { networks },
    } = container;
    const networkNumber = Number.parseInt(rawNn, 10);

    networks[networkId] = {
      networkNumber,
      networkType,
    } as ManifestNetwork;
  },
  subnetmask: (container, input) => {
    const {
      dataset: { networkId = '' },
      value,
    } = input;
    const {
      networkConfig: { networks },
    } = container;

    networks[networkId].networkSubnetMask = value;
  },
};

const buildInputIdANGateway = (networkId: string): string =>
  `${INPUT_ID_PREFIX_AN_NETWORK}-${networkId}-gateway`;

const buildInputIdANMinIp = (networkId: string): string =>
  `${INPUT_ID_PREFIX_AN_NETWORK}-${networkId}-min-ip`;

const buildInputIdANNetworkType = (networkId: string): string =>
  `${INPUT_ID_PREFIX_AN_NETWORK}-${networkId}-network-type`;

const buildInputIdANSubnetMask = (networkId: string): string =>
  `${INPUT_ID_PREFIX_AN_NETWORK}-${networkId}-subnet-mask`;

const AnNetworkInputGroup = <M extends MapToInputTestID>({
  debounceWait = 500,
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    buildInputUnmountFunction,
    setMessage,
  },
  inputGatewayLabel = 'Gateway',
  inputMinIpLabel = 'IP address',
  inputSubnetMaskLabel = 'Subnet mask',
  networkId,
  networkNumber,
  networkType,
  networkTypeOptions,
  onClose,
  onNetworkGatewayChange,
  onNetworkMinIpChange,
  onNetworkSubnetMaskChange,
  onNetworkTypeChange,
  previous: {
    gateway: previousGateway,
    minIp: previousIpAddress,
    subnetMask: previousSubnetMask,
  } = {},
  readonlyNetworkName: isReadonlyNetworkName,
  showCloseButton: isShowCloseButton,
  showGateway: isShowGateway,
}: AnNetworkInputGroupProps<M>): React.ReactElement => {
  const networkName = useMemo(
    () => `${NETWORK_TYPES[networkType]} ${networkNumber}`,
    [networkNumber, networkType],
  );

  const inputCellIdGateway = useMemo(
    () => `${INPUT_CELL_ID_PREFIX_AN}-${networkId}-gateway`,
    [networkId],
  );
  const inputCellIdIp = useMemo(
    () => `${INPUT_CELL_ID_PREFIX_AN}-${networkId}-ip`,
    [networkId],
  );
  const inputCellIdSubnetMask = useMemo(
    () => `${INPUT_CELL_ID_PREFIX_AN}-${networkId}-subnet-mask`,
    [networkId],
  );

  const inputIdANNetwork = useMemo(
    () => `${INPUT_ID_PREFIX_AN_NETWORK}-${networkId}`,
    [networkId],
  );

  const inputIdGateway = useMemo(
    () => buildInputIdANGateway(networkId),
    [networkId],
  );
  const inputIdMinIp = useMemo(
    () => buildInputIdANMinIp(networkId),
    [networkId],
  );
  const inputIdNetworkType = useMemo(
    () => buildInputIdANNetworkType(networkId),
    [networkId],
  );
  const inputIdSubnetMask = useMemo(
    () => buildInputIdANSubnetMask(networkId),
    [networkId],
  );

  const inputCellGatewayDisplay = useMemo(
    () => (isShowGateway ? undefined : 'none'),
    [isShowGateway],
  );

  const debounceNetworkGatewayChangeHandler = useMemo(
    () =>
      onNetworkGatewayChange && debounce(onNetworkGatewayChange, debounceWait),
    [debounceWait, onNetworkGatewayChange],
  );

  const debounceNetworkMinIpChangeHandler = useMemo(
    () => onNetworkMinIpChange && debounce(onNetworkMinIpChange, debounceWait),
    [debounceWait, onNetworkMinIpChange],
  );

  const debounceNetworkSubnetMaskChangeHandler = useMemo(
    () =>
      onNetworkSubnetMaskChange &&
      debounce(onNetworkSubnetMaskChange, debounceWait),
    [debounceWait, onNetworkSubnetMaskChange],
  );

  const closeButtonElement = useMemo<ReactNode>(
    () =>
      isShowCloseButton && (
        <IconButton
          mapPreset="close"
          iconProps={{ fontSize: 'small' }}
          onClick={(...args) => {
            onClose?.call(null, { networkId, networkType }, ...args);
          }}
          sx={{
            padding: '.2em',
            position: 'absolute',
            right: '-.6rem',
            top: '-.2rem',
          }}
        />
      ),
    [isShowCloseButton, networkId, networkType, onClose],
  );

  const inputGatewayElement = useMemo<ReactNode>(() => {
    let result: ReactNode;

    if (isShowGateway && inputIdGateway) {
      result = (
        <InputWithRef
          createInputOnChangeHandlerOptions={{
            postSet: (...args) =>
              debounceNetworkGatewayChangeHandler?.call(
                null,
                { networkId, networkType },
                ...args,
              ),
          }}
          input={
            <OutlinedInputWithLabel
              baseInputProps={{
                'data-handler': 'gateway',
                'data-network-id': networkId,
              }}
              id={inputIdGateway}
              label={inputGatewayLabel}
              value={previousGateway}
            />
          }
          inputTestBatch={buildIPAddressTestBatch(
            `${networkName} ${inputGatewayLabel}`,
            () => {
              setMessage(inputIdGateway);
            },
            {
              onFinishBatch: buildFinishInputTestBatchFunction(inputIdGateway),
            },
            (message) => {
              setMessage(inputIdGateway, { children: message });
            },
          )}
          onFirstRender={buildInputFirstRenderFunction(inputIdGateway)}
          onUnmount={buildInputUnmountFunction(inputIdGateway)}
          required={isShowGateway}
        />
      );
    }

    return result;
  }, [
    isShowGateway,
    inputIdGateway,
    networkId,
    inputGatewayLabel,
    previousGateway,
    networkName,
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    buildInputUnmountFunction,
    debounceNetworkGatewayChangeHandler,
    networkType,
    setMessage,
  ]);

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <InputWithRef
          input={
            <SelectWithLabel
              id={inputIdNetworkType}
              isReadOnly={isReadonlyNetworkName}
              onChange={(...args) => {
                onNetworkTypeChange?.call(
                  null,
                  { networkId, networkType },
                  ...args,
                );
              }}
              selectItems={networkTypeOptions}
              selectProps={{
                renderValue: () => networkName,
              }}
              value={networkType}
            />
          }
        />
        {closeButtonElement}
      </InnerPanelHeader>
      <InnerPanelBody>
        <input
          hidden
          id={inputIdANNetwork}
          readOnly
          data-handler="network"
          data-network-id={networkId}
          data-network-number={networkNumber}
          data-network-type={networkType}
        />
        <Grid
          columns={{ xs: 1, sm: 2, md: 3 }}
          layout={{
            [inputCellIdIp]: {
              children: (
                <InputWithRef
                  createInputOnChangeHandlerOptions={{
                    postSet: (...args) =>
                      debounceNetworkMinIpChangeHandler?.call(
                        null,
                        { networkId, networkType },
                        ...args,
                      ),
                  }}
                  input={
                    <OutlinedInputWithLabel
                      baseInputProps={{
                        'data-handler': 'minip',
                        'data-network-id': networkId,
                      }}
                      id={inputIdMinIp}
                      label={inputMinIpLabel}
                      value={previousIpAddress}
                    />
                  }
                  inputTestBatch={buildIPAddressTestBatch(
                    `${networkName} ${inputMinIpLabel}`,
                    () => {
                      setMessage(inputIdMinIp);
                    },
                    {
                      onFinishBatch:
                        buildFinishInputTestBatchFunction(inputIdMinIp),
                    },
                    (message) => {
                      setMessage(inputIdMinIp, { children: message });
                    },
                  )}
                  onFirstRender={buildInputFirstRenderFunction(inputIdMinIp)}
                  onUnmount={buildInputUnmountFunction(inputIdMinIp)}
                  required
                />
              ),
            },
            [inputCellIdSubnetMask]: {
              children: (
                <InputWithRef
                  createInputOnChangeHandlerOptions={{
                    postSet: (...args) =>
                      debounceNetworkSubnetMaskChangeHandler?.call(
                        null,
                        { networkId, networkType },
                        ...args,
                      ),
                  }}
                  input={
                    <OutlinedInputWithLabel
                      baseInputProps={{
                        'data-handler': 'subnetmask',
                        'data-network-id': networkId,
                      }}
                      id={inputIdSubnetMask}
                      label={inputSubnetMaskLabel}
                      value={previousSubnetMask}
                    />
                  }
                  inputTestBatch={buildIPAddressTestBatch(
                    `${networkName} ${inputSubnetMaskLabel}`,
                    () => {
                      setMessage(inputIdSubnetMask);
                    },
                    {
                      onFinishBatch:
                        buildFinishInputTestBatchFunction(inputIdSubnetMask),
                    },
                    (message) => {
                      setMessage(inputIdSubnetMask, { children: message });
                    },
                  )}
                  onFirstRender={buildInputFirstRenderFunction(
                    inputIdSubnetMask,
                  )}
                  onUnmount={buildInputUnmountFunction(inputIdSubnetMask)}
                  required
                />
              ),
            },
            [inputCellIdGateway]: {
              children: inputGatewayElement,
              display: inputCellGatewayDisplay,
            },
          }}
          spacing="1em"
        />
      </InnerPanelBody>
    </InnerPanel>
  );
};

export {
  INPUT_ID_PREFIX_AN_NETWORK,
  MAP_TO_AN_INPUT_HANDLER,
  buildInputIdANGateway,
  buildInputIdANMinIp,
  buildInputIdANNetworkType,
  buildInputIdANSubnetMask,
};

export default AnNetworkInputGroup;
