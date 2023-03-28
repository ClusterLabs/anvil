import { ReactElement, ReactNode, useEffect, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import Grid from '../Grid';
import IconButton from '../IconButton';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SelectWithLabel from '../SelectWithLabel';
import { buildIPAddressTestBatch } from '../../lib/test_input';

const AnNetworkInputGroup = <M extends MapToInputTestID>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
    setMsgSetter,
  },
  idPrefix,
  inputGatewayId,
  inputGatewayLabel = 'Gateway',
  inputMinIpId,
  inputMinIpLabel = 'IP address',
  inputNetworkTypeId,
  inputSubnetMaskId,
  inputSubnetMaskLabel = 'Subnet mask',
  networkId,
  networkNumber,
  networkType,
  networkTypeOptions,
  onClose,
  onNetworkTypeChange,
  previous: {
    gateway: previousGateway,
    minIp: previousIpAddress,
    subnetMask: previousSubnetMask,
  } = {},
  readonlyNetworkName: isReadonlyNetworkName,
  showCloseButton: isShowCloseButton,
  showGateway: isShowGateway,
}: AnNetworkInputGroupProps<M>): ReactElement => {
  const networkName = useMemo(
    () => `${NETWORK_TYPES[networkType]} ${networkNumber}`,
    [networkNumber, networkType],
  );

  const inputCellGatewayId = useMemo(
    () => `${idPrefix}-input-cell-gateway`,
    [idPrefix],
  );
  const inputCellIpId = useMemo(() => `${idPrefix}-input-cell-ip`, [idPrefix]);
  const inputCellSubnetMaskId = useMemo(
    () => `${idPrefix}-input-cell-subnet-mask`,
    [idPrefix],
  );

  const inputCellGatewayDisplay = useMemo(
    () => (isShowGateway ? undefined : 'none'),
    [isShowGateway],
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

    if (isShowGateway && inputGatewayId) {
      setMsgSetter(inputGatewayId);

      result = (
        <InputWithRef
          input={
            <OutlinedInputWithLabel
              id={inputGatewayId}
              label={inputGatewayLabel}
              value={previousGateway}
            />
          }
          inputTestBatch={buildIPAddressTestBatch(
            `${networkName} ${inputGatewayLabel}`,
            () => {
              msgSetters[inputGatewayId]();
            },
            {
              onFinishBatch: buildFinishInputTestBatchFunction(inputGatewayId),
            },
            (message) => {
              msgSetters[inputGatewayId]({
                children: message,
              });
            },
          )}
          onFirstRender={buildInputFirstRenderFunction(inputGatewayId)}
          required={isShowGateway}
        />
      );
    }

    return result;
  }, [
    isShowGateway,
    inputGatewayId,
    setMsgSetter,
    inputGatewayLabel,
    previousGateway,
    networkName,
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
  ]);

  useEffect(() => {
    setMsgSetter(inputMinIpId);
    setMsgSetter(inputSubnetMaskId);
  }, [inputMinIpId, inputSubnetMaskId, setMsgSetter]);

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <InputWithRef
          input={
            <SelectWithLabel
              id={inputNetworkTypeId}
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
        <Grid
          layout={{
            [inputCellIpId]: {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id={inputMinIpId}
                      label={inputMinIpLabel}
                      value={previousIpAddress}
                    />
                  }
                  inputTestBatch={buildIPAddressTestBatch(
                    `${networkName} ${inputMinIpLabel}`,
                    () => {
                      msgSetters[inputMinIpId]();
                    },
                    {
                      onFinishBatch:
                        buildFinishInputTestBatchFunction(inputMinIpId),
                    },
                    (message) => {
                      msgSetters[inputMinIpId]({
                        children: message,
                      });
                    },
                  )}
                  onFirstRender={buildInputFirstRenderFunction(inputMinIpId)}
                  required
                />
              ),
            },
            [inputCellSubnetMaskId]: {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      id={inputSubnetMaskId}
                      label={inputSubnetMaskLabel}
                      value={previousSubnetMask}
                    />
                  }
                  required
                />
              ),
            },
            [inputCellGatewayId]: {
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

export default AnNetworkInputGroup;
