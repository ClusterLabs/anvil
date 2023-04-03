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

const MAP_TO_AH_INPUT_HANDLER: MapToManifestFormInputHandler = {
  fence: (container, input) => {
    const {
      dataset: { hostId = '', fenceId = '', fenceName = '' },
      value: fencePort,
    } = input;
    const {
      hostConfig: {
        hosts: { [hostId]: host },
      },
    } = container;
    const { fences = {} } = host;

    fences[fenceId] = {
      fenceName,
      fencePort,
    };
    host.fences = fences;
  },
  host: (container, input) => {
    const {
      dataset: { hostId = '', hostNumber: rawHostNumber = '', hostType = '' },
    } = input;
    const hostNumber = Number.parseInt(rawHostNumber, 10);

    container.hostConfig.hosts[hostId] = {
      hostNumber,
      hostType,
    };
  },
  network: (container, input) => {
    const {
      dataset: {
        hostId = '',
        networkId = '',
        networkNumber: rawNetworkNumber = '',
        networkType = '',
      },
      value: networkIp,
    } = input;
    const {
      hostConfig: {
        hosts: { [hostId]: host },
      },
    } = container;
    const { networks = {} } = host;
    const networkNumber = Number.parseInt(rawNetworkNumber, 10);

    networks[networkId] = {
      networkIp,
      networkNumber,
      networkType,
    };
    host.networks = networks;
  },
  ups: (container, input) => {
    const {
      checked: isUsed,
      dataset: { hostId = '', upsId = '', upsName = '' },
    } = input;
    const {
      hostConfig: {
        hosts: { [hostId]: host },
      },
    } = container;
    const { upses = {} } = host;

    upses[upsId] = {
      isUsed,
      upsName,
    };
    host.upses = upses;
  },
};

const GRID_COLUMNS = { xs: 1, sm: 2, md: 3 };
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
    buildInputUnmountFunction,
    setMessage,
  },
  hostId,
  hostNumber,
  hostType,
  previous: {
    fences: fenceList = {},
    networks: networkList = {},
    upses: upsList = {},
  } = {},
  // Props that depend on others.
  hostLabel = `${hostType} ${hostNumber}`,
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

  const isShowUpsListGrid = useMemo(
    () => Boolean(upsListEntries.length),
    [upsListEntries.length],
  );

  const inputIdAHHost = useMemo(
    () => `${INPUT_ID_PREFIX_AN_HOST}-${hostId}`,
    [hostId],
  );

  const fenceListGridLayout = useMemo(
    () =>
      fenceListEntries.reduce<GridLayout>(
        (previous, [fenceId, { fenceName, fencePort }]) => {
          const cellId = `${INPUT_CELL_ID_PREFIX_AH}-${hostId}-${fenceId}-port`;

          const inputId = buildInputIdAHFencePort(hostId, fenceId);
          const inputLabel = `Port on ${fenceName}`;

          previous[cellId] = {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    baseInputProps={{
                      'data-handler': 'fence',
                      'data-host-id': hostId,
                      'data-fence-id': fenceId,
                      'data-fence-name': fenceName,
                    }}
                    id={inputId}
                    label={inputLabel}
                    value={fencePort}
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  `${hostId} ${inputLabel}`,
                  () => {
                    setMessage(inputId);
                  },
                  { onFinishBatch: buildFinishInputTestBatchFunction(inputId) },
                  (message) => {
                    setMessage(inputId, { children: message });
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
      setMessage,
    ],
  );

  const networkListGridLayout = useMemo(
    () =>
      networkListEntries.reduce<GridLayout>(
        (previous, [networkId, { networkIp, networkNumber, networkType }]) => {
          const cellId = `${INPUT_CELL_ID_PREFIX_AH}-${hostId}-${networkId}-ip`;

          const inputId = buildInputIdAHNetworkIp(hostId, networkId);
          const inputLabel = `${NETWORK_TYPES[networkType]} ${networkNumber}`;

          previous[cellId] = {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    baseInputProps={{
                      'data-handler': 'network',
                      'data-host-id': hostId,
                      'data-network-id': networkId,
                      'data-network-number': networkNumber,
                      'data-network-type': networkType,
                    }}
                    id={inputId}
                    label={inputLabel}
                    value={networkIp}
                  />
                }
                inputTestBatch={buildIPAddressTestBatch(
                  `${hostId} ${inputLabel}`,
                  () => {
                    setMessage(inputId);
                  },
                  { onFinishBatch: buildFinishInputTestBatchFunction(inputId) },
                  (message) => {
                    setMessage(inputId, { children: message });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(inputId)}
                onUnmount={buildInputUnmountFunction(inputId)}
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
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      buildInputUnmountFunction,
      setMessage,
    ],
  );

  const upsListGridLayout = useMemo(
    () =>
      upsListEntries.reduce<GridLayout>(
        (previous, [upsId, { isUsed, upsName }]) => {
          const cellId = `${INPUT_CELL_ID_PREFIX_AH}-${hostId}-${upsId}-power-host`;

          const inputId = buildInputIdAHUpsPowerHost(hostId, upsId);
          const inputLabel = `Uses ${upsName}`;

          previous[cellId] = {
            children: (
              <InputWithRef
                input={
                  <SwitchWithLabel
                    baseInputProps={{
                      'data-handler': 'ups',
                      'data-host-id': hostId,
                      'data-ups-id': upsId,
                      'data-ups-name': upsName,
                    }}
                    checked={isUsed}
                    id={inputId}
                    label={inputLabel}
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

  const upsListGrid = useMemo(
    () =>
      isShowUpsListGrid && (
        <Grid
          columns={GRID_COLUMNS}
          layout={upsListGridLayout}
          spacing={GRID_SPACING}
        />
      ),
    [isShowUpsListGrid, upsListGridLayout],
  );

  return (
    <InnerPanel mv={0}>
      <InnerPanelHeader>
        <BodyText>{hostLabel}</BodyText>
      </InnerPanelHeader>
      <InnerPanelBody>
        <input
          hidden
          id={inputIdAHHost}
          readOnly
          data-handler="host"
          data-host-id={hostId}
          data-host-number={hostNumber}
          data-host-type={hostType}
        />
        <FlexBox>
          <Grid
            columns={GRID_COLUMNS}
            layout={{
              ...networkListGridLayout,
              ...fenceListGridLayout,
            }}
            spacing={GRID_SPACING}
          />
          {upsListGrid}
        </FlexBox>
      </InnerPanelBody>
    </InnerPanel>
  );
};

export {
  INPUT_ID_PREFIX_AN_HOST,
  MAP_TO_AH_INPUT_HANDLER,
  buildInputIdAHFencePort,
  buildInputIdAHNetworkIp,
  buildInputIdAHUpsPowerHost,
};

export default AnHostInputGroup;
