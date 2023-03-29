import { ReactElement, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import FlexBox from '../FlexBox';
import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import { InnerPanel, InnerPanelBody, InnerPanelHeader } from '../Panels';
import SwitchWithLabel from '../SwitchWithLabel';
import {
  buildIPAddressTestBatch,
  buildPeacefulStringTestBatch,
} from '../../lib/test_input';
import { BodyText } from '../Text';

const INPUT_ID_PREFIX_AN_HOST = 'an-host-input';

const INPUT_CELL_ID_PREFIX_AH = `${INPUT_ID_PREFIX_AN_HOST}-cell`;

const GRID_SPACING = '1em';

const buildInputIdAHFencePort = (hostId: string, fenceId: string): string =>
  `${INPUT_ID_PREFIX_AN_HOST}-${hostId}-${fenceId}-port`;

const buildInputIdAHNetworkIp = (hostId: string, networkId: string): string =>
  `${INPUT_ID_PREFIX_AN_HOST}-${hostId}-${networkId}-ip`;

const buildInputIdAHUpsPowerHost = (hostId: string, upsId: string): string =>
  `${INPUT_ID_PREFIX_AN_HOST}-${hostId}-${upsId}-power-host`;

const AnHostInputGroup = <M extends MapToInputTestID>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
    setMsgSetter,
  },
  hostId,
  hostLabel,
  previous: {
    fences: fenceList = {},
    networks: networkList = {},
    upses: upsList = {},
  } = {},
}: AnHostInputGroupProps<M>): ReactElement => {
  const fenceListEntries = useMemo(
    () => Object.entries(fenceList),
    [fenceList],
  );
  const networkListEntries = useMemo(
    () => Object.entries(networkList),
    [networkList],
  );
  const upsListEntries = useMemo(() => Object.entries(upsList), [upsList]);

  const isShowFenceListGrid = useMemo(
    () => Boolean(fenceListEntries.length),
    [fenceListEntries.length],
  );
  const isShowUpsListGrid = useMemo(
    () => Boolean(upsListEntries.length),
    [upsListEntries.length],
  );
  const isShowFenceAndUpsListGrid = useMemo(
    () => isShowFenceListGrid || isShowUpsListGrid,
    [isShowFenceListGrid, isShowUpsListGrid],
  );

  const fenceListGridLayout = useMemo(
    () =>
      fenceListEntries.reduce<GridLayout>(
        (previous, [fenceId, { fenceName, fencePort }]) => {
          const cellId = `${INPUT_CELL_ID_PREFIX_AH}-${fenceId}-port`;

          const inputId = buildInputIdAHFencePort(hostId, fenceId);
          const inputLabel = `Port on ${fenceName}`;

          setMsgSetter(inputId);

          previous[cellId] = {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id={inputId}
                    label={inputLabel}
                    value={fencePort}
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  inputLabel,
                  () => {
                    msgSetters[inputId]();
                  },
                  { onFinishBatch: buildFinishInputTestBatchFunction(inputId) },
                  (message) => {
                    msgSetters[inputId]({ children: message });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(inputId)}
                required
              />
            ),
          };

          return previous;
        },
        {},
      ),
    [
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      fenceListEntries,
      hostId,
      msgSetters,
      setMsgSetter,
    ],
  );

  const networkListGridLayout = useMemo(
    () =>
      networkListEntries.reduce<GridLayout>(
        (previous, [networkId, { networkIp, networkNumber, networkType }]) => {
          const cellId = `${INPUT_CELL_ID_PREFIX_AH}-${networkId}-ip`;

          const inputId = buildInputIdAHNetworkIp(hostId, networkIp);
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
                    msgSetters[inputId]({ children: message });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(inputId)}
                required
              />
            ),
          };

          return previous;
        },
        {},
      ),
    [
      networkListEntries,
      hostId,
      setMsgSetter,
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      msgSetters,
    ],
  );

  const upsListGridLayout = useMemo(
    () =>
      upsListEntries.reduce<GridLayout>(
        (previous, [upsId, { isUsed, upsName }]) => {
          const cellId = `${INPUT_CELL_ID_PREFIX_AH}-${upsId}-power-host`;

          const inputId = buildInputIdAHUpsPowerHost(hostId, upsId);
          const inputLabel = `Uses ${upsName}`;

          previous[cellId] = {
            children: (
              <InputWithRef
                input={
                  <SwitchWithLabel
                    checked={isUsed}
                    id={inputId}
                    label={inputLabel}
                    flexBoxProps={{ height: '3.5em' }}
                  />
                }
                valueType="boolean"
              />
            ),
          };

          return previous;
        },
        {},
      ),
    [hostId, upsListEntries],
  );

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <BodyText>{hostLabel}</BodyText>
      </InnerPanelHeader>
      <InnerPanelBody>
        <FlexBox>
          <Grid
            columns={{ xs: 1, sm: 2, md: 3 }}
            layout={networkListGridLayout}
            spacing={GRID_SPACING}
          />
          {isShowFenceAndUpsListGrid && (
            <Grid
              columns={{ xs: 1, sm: 2 }}
              layout={{
                'an-host-fence-input-group': {
                  children: (
                    <Grid
                      columns={{ xs: 1, md: 2 }}
                      layout={fenceListGridLayout}
                      spacing={GRID_SPACING}
                    />
                  ),
                },
                'an-host-ups-input-group': {
                  children: (
                    <Grid
                      columns={{ xs: 1, md: 2 }}
                      layout={upsListGridLayout}
                      spacing={GRID_SPACING}
                    />
                  ),
                },
              }}
              spacing={GRID_SPACING}
            />
          )}
        </FlexBox>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export {
  buildInputIdAHFencePort,
  buildInputIdAHNetworkIp,
  buildInputIdAHUpsPowerHost,
};

export default AnHostInputGroup;
