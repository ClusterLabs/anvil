import { ReactElement, ReactNode, useEffect, useMemo } from 'react';

import Grid from '../Grid';
import IconButton from '../IconButton';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import { buildIPAddressTestBatch } from '../../lib/test_input';
import { BodyText } from '../Text';

const AnvilNetworkInputGroup = <M extends MapToInputTestID>({
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
  inputSubnetMaskId,
  inputSubnetMaskLabel = 'Subnet mask',
  networkName,
  previous: {
    gateway: previousGateway,
    minIp: previousIpAddress,
    subnetMask: previousSubnetMask,
  } = {},
  showGateway: isShowGateway,
}: AnvilNetworkInputGroupProps<M>): ReactElement => {
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
    msgSetters,
  ]);

  useEffect(() => {
    setMsgSetter(inputMinIpId);
    setMsgSetter(inputSubnetMaskId);
  }, [inputMinIpId, inputSubnetMaskId, setMsgSetter]);

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <BodyText>{networkName}</BodyText>
        <IconButton
          mapPreset="close"
          iconProps={{ fontSize: 'small' }}
          sx={{
            padding: '.2em',
            position: 'absolute',
            right: '-.6rem',
            top: '-.2rem',
          }}
        />
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

export default AnvilNetworkInputGroup;
