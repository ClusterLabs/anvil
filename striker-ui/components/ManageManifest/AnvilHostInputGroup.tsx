import { ReactElement, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SwitchWithLabel from '../SwitchWithLabel';
import {
  buildIPAddressTestBatch,
  buildNumberTestBatch,
} from '../../lib/test_input';
import { BodyText } from '../Text';

const INPUT_ID_PREFIX_ANVIL_HOST_CONFIG = 'anvil-host-config-input';

const INPUT_CELL_ID_PREFIX_ANVIL_HOST_CONFIG = `${INPUT_ID_PREFIX_ANVIL_HOST_CONFIG}-cell`;

const AnvilHostInputGroup = <M extends MapToInputTestID>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
    setMsgSetter,
  },
  hostLabel,
  previous: { fences = {}, networks = {}, upses = {} } = {},
}: AnvilHostInputGroupProps<M>): ReactElement => {
  const gridLayout = useMemo(() => {
    let result: GridLayout = {};

    result = Object.entries(networks).reduce<GridLayout>(
      (previous, [networkId, { networkIp, networkNumber, networkType }]) => {
        const idPostfix = `${networkId}-ip`;

        const cellId = `${INPUT_CELL_ID_PREFIX_ANVIL_HOST_CONFIG}-${idPostfix}`;

        const inputId = `${INPUT_ID_PREFIX_ANVIL_HOST_CONFIG}-${idPostfix}`;
        const inputLabel = `${NETWORK_TYPES[networkType]} ${networkNumber}`;

        setMsgSetter(inputId);

        previous[cellId] = {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={inputId}
                  label={inputLabel}
                  value={networkIp}
                />
              }
              inputTestBatch={buildIPAddressTestBatch(
                inputLabel,
                () => {
                  msgSetters[inputId]();
                },
                { onFinishBatch: buildFinishInputTestBatchFunction(inputId) },
                (message) => {
                  msgSetters[inputId]({
                    children: message,
                  });
                },
              )}
              onFirstRender={buildInputFirstRenderFunction(inputId)}
              required
            />
          ),
        };

        return previous;
      },
      result,
    );

    result = Object.entries(fences).reduce<GridLayout>(
      (previous, [fenceId, { fenceName, fencePort }]) => {
        const idPostfix = `${fenceId}-port`;

        const cellId = `${INPUT_CELL_ID_PREFIX_ANVIL_HOST_CONFIG}-${idPostfix}`;

        const inputId = `${INPUT_ID_PREFIX_ANVIL_HOST_CONFIG}-${idPostfix}`;
        const inputLabel = fenceName;

        setMsgSetter(inputId);

        previous[cellId] = {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={inputId}
                  label={fenceName}
                  value={fencePort}
                />
              }
              inputTestBatch={buildNumberTestBatch(
                inputLabel,
                () => {
                  msgSetters[inputId]();
                },
                { onFinishBatch: buildFinishInputTestBatchFunction(inputId) },
                (message) => {
                  msgSetters[inputId]({
                    children: message,
                  });
                },
              )}
              required
              valueType="number"
            />
          ),
        };

        return previous;
      },
      result,
    );

    result = Object.entries(upses).reduce<GridLayout>(
      (previous, [upsId, { isPowerHost, upsName }]) => {
        const idPostfix = `${upsId}-power-host`;

        const cellId = `${INPUT_CELL_ID_PREFIX_ANVIL_HOST_CONFIG}-${idPostfix}`;

        const inputId = `${INPUT_ID_PREFIX_ANVIL_HOST_CONFIG}-${idPostfix}`;

        previous[cellId] = {
          children: (
            <InputWithRef
              input={
                <SwitchWithLabel
                  id={inputId}
                  label={upsName}
                  checked={isPowerHost}
                />
              }
              valueType="boolean"
            />
          ),
        };

        return previous;
      },
      result,
    );

    return result;
  }, [
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMsgSetter,
    fences,
    msgSetters,
    networks,
    upses,
  ]);

  return (
    <InnerPanel>
      <InnerPanelHeader>
        <BodyText>{hostLabel}</BodyText>
      </InnerPanelHeader>
      <InnerPanelBody>
        <Grid layout={gridLayout} spacing="1em" />
      </InnerPanelBody>
    </InnerPanel>
  );
};

export default AnvilHostInputGroup;
