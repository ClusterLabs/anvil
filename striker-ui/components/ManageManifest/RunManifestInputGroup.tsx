import { styled } from '@mui/material';
import { ReactElement, useMemo, useRef } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import FlexBox from '../FlexBox';
import Grid from '../Grid';
import InputWithRef, { InputForwardedRefContent } from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import SelectWithLabel from '../SelectWithLabel';
import { buildPeacefulStringTestBatch } from '../../lib/test_input';
import { BodyText, MonoText } from '../Text';

const INPUT_ID_PREFIX_RUN_MANIFEST = 'run-manifest-input';
const INPUT_ID_PREFIX_RM_HOST = `${INPUT_ID_PREFIX_RUN_MANIFEST}-host`;

const INPUT_ID_RM_AN_DESCRIPTION = `${INPUT_ID_PREFIX_RUN_MANIFEST}-an-description`;
const INPUT_ID_RM_AN_PASSWORD = `${INPUT_ID_PREFIX_RUN_MANIFEST}-an-password`;
const INPUT_ID_RM_AN_CONFIRM_PASSWORD = `${INPUT_ID_PREFIX_RUN_MANIFEST}-an-confirm-password`;

const INPUT_LABEL_RM_AN_DESCRIPTION = 'Description';
const INPUT_LABEL_RM_AN_PASSWORD = 'Password';
const INPUT_LABEL_RM_AN_CONFIRM_PASSWORD = 'Confirm password';

const MANIFEST_PARAM_NONE = '--';

const EndMono = styled(MonoText)({
  justifyContent: 'end',
});

const buildInputIdRMHost = (hostId: string): string =>
  `${INPUT_ID_PREFIX_RM_HOST}-${hostId}`;

const RunManifestInputGroup = <M extends MapToInputTestID>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMessage,
  },
  knownFences = {},
  knownHosts = {},
  knownUpses = {},
  previous: { domain: anDomain, hostConfig = {}, networkConfig = {} } = {},
}: RunManifestInputGroupProps<M>): ReactElement => {
  const passwordRef = useRef<InputForwardedRefContent<'string'>>({});

  const { hosts: initHostList = {} } = hostConfig;
  const { dnsCsv, networks: initNetworkList = {}, ntpCsv } = networkConfig;

  const hostListEntries = useMemo(
    () => Object.entries(initHostList),
    [initHostList],
  );
  const knownFenceListEntries = useMemo(
    () => Object.entries(knownFences),
    [knownFences],
  );
  const knownHostListEntries = useMemo(
    () => Object.entries(knownHosts),
    [knownHosts],
  );
  const knownUpsListEntries = useMemo(
    () => Object.entries(knownUpses),
    [knownUpses],
  );
  const networkListEntries = useMemo(
    () => Object.entries(initNetworkList),
    [initNetworkList],
  );

  const hostOptionList = useMemo(
    () =>
      knownHostListEntries.map<SelectItem>(([, { hostName, hostUUID }]) => ({
        displayValue: hostName,
        value: hostUUID,
      })),
    [knownHostListEntries],
  );

  const {
    headers: hostHeaderRow,
    hosts: hostSelectRow,
    hostNames: hostNewNameRow,
  } = useMemo(
    () =>
      hostListEntries.reduce<{
        headers: GridLayout;
        hosts: GridLayout;
        hostNames: GridLayout;
      }>(
        (previous, [hostId, { hostName, hostNumber, hostType }]) => {
          const { headers, hosts, hostNames } = previous;

          const prettyId = `${hostType.replace(
            'node',
            'subnode',
          )} ${hostNumber}`;

          headers[`run-manifest-column-header-cell-${hostId}`] = {
            children: <BodyText>{prettyId}</BodyText>,
          };

          const inputId = buildInputIdRMHost(hostId);
          const inputLabel = `${prettyId} host`;

          hosts[`run-manifest-host-cell-${hostId}`] = {
            children: (
              <InputWithRef
                input={
                  <SelectWithLabel
                    id={inputId}
                    label={inputLabel}
                    selectItems={hostOptionList}
                    value=""
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  inputLabel,
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

          hostNames[`run-manifest-new-host-name-cell-${hostId}`] = {
            children: (
              <MonoText>
                {hostName}.{anDomain}
              </MonoText>
            ),
          };

          return previous;
        },
        {
          headers: {
            'run-manifest-column-header-cell-offset': {},
          },
          hosts: {
            'run-manifest-host-cell-header': {
              children: <BodyText>Uses host</BodyText>,
            },
          },
          hostNames: {
            'run-manifest-new-host-name-cell-header': {
              children: <BodyText>New hostname</BodyText>,
            },
          },
        },
      ),
    [
      anDomain,
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      hostListEntries,
      hostOptionList,
      setMessage,
    ],
  );

  const {
    gateway: defaultGatewayGridLayout,
    hostNetworks: hostNetworkRowList,
  } = useMemo(
    () =>
      networkListEntries.reduce<{
        gateway: GridLayout;
        hostNetworks: GridLayout;
      }>(
        (
          previous,
          [networkId, { networkGateway, networkNumber, networkType }],
        ) => {
          const { gateway, hostNetworks } = previous;

          const idPrefix = `run-manifest-host-network-cell-${networkId}`;

          const networkShortName = `${networkType.toUpperCase()}${networkNumber}`;

          hostNetworks[`${idPrefix}-header`] = {
            children: <BodyText>{networkShortName}</BodyText>,
          };

          hostListEntries.forEach(([hostId, { networks = {} }]) => {
            const { [networkId]: { networkIp: ip = '' } = {} } = networks;

            hostNetworks[`${idPrefix}-${hostId}-ip`] = {
              children: <MonoText>{ip || MANIFEST_PARAM_NONE}</MonoText>,
            };
          });

          const cellId = 'run-manifest-gateway-cell';

          if (networkGateway && !gateway[cellId]) {
            gateway[cellId] = {
              children: <EndMono>{networkGateway}</EndMono>,
            };
          }

          return previous;
        },
        {
          gateway: {
            'run-manifest-gateway-cell-header': {
              children: <BodyText>Gateway</BodyText>,
            },
          },
          hostNetworks: {},
        },
      ),
    [hostListEntries, networkListEntries],
  );

  const hostFenceRowList = useMemo(
    () =>
      knownFenceListEntries.reduce<GridLayout>(
        (previous, [fenceUuid, { fenceName }]) => {
          const idPrefix = `run-manifest-fence-cell-${fenceUuid}`;

          previous[`${idPrefix}-header`] = {
            children: <BodyText>Port on {fenceName}</BodyText>,
          };

          hostListEntries.forEach(([hostId, { fences = {} }]) => {
            const { [fenceName]: { fencePort = '' } = {} } = fences;

            previous[`${idPrefix}-${hostId}-port`] = {
              children: <MonoText>{fencePort || MANIFEST_PARAM_NONE}</MonoText>,
            };
          });

          return previous;
        },
        {},
      ),
    [hostListEntries, knownFenceListEntries],
  );

  const hostUpsRowList = useMemo(
    () =>
      knownUpsListEntries.reduce<GridLayout>(
        (previous, [upsUuid, { upsName }]) => {
          const idPrefix = `run-manifest-ups-cell-${upsUuid}`;

          previous[`${idPrefix}-header`] = {
            children: <BodyText>Uses {upsName}</BodyText>,
          };

          hostListEntries.forEach(([hostId, { upses = {} }]) => {
            const { [upsName]: { isUsed = false } = {} } = upses;

            previous[`${idPrefix}-${hostId}-is-used`] = {
              children: <MonoText>{isUsed ? 'yes' : 'no'}</MonoText>,
            };
          });

          return previous;
        },
        {},
      ),
    [hostListEntries, knownUpsListEntries],
  );

  const confirmPasswordProps = useMemo(() => {
    const inputTestBatch = buildPeacefulStringTestBatch(
      INPUT_LABEL_RM_AN_CONFIRM_PASSWORD,
      () => {
        setMessage(INPUT_ID_RM_AN_CONFIRM_PASSWORD);
      },
      {
        onFinishBatch: buildFinishInputTestBatchFunction(
          INPUT_ID_RM_AN_CONFIRM_PASSWORD,
        ),
      },
      (message) => {
        setMessage(INPUT_ID_RM_AN_CONFIRM_PASSWORD, { children: message });
      },
    );

    const onFirstRender = buildInputFirstRenderFunction(
      INPUT_ID_RM_AN_CONFIRM_PASSWORD,
    );

    inputTestBatch.tests.push({
      onFailure: () => {
        setMessage(INPUT_ID_RM_AN_CONFIRM_PASSWORD, {
          children: <>Confirm password must match password.</>,
        });
      },
      test: ({ value }) => passwordRef.current.getValue?.call(null) === value,
    });

    return {
      inputTestBatch,
      onFirstRender,
    };
  }, [
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMessage,
  ]);

  return (
    <FlexBox>
      <Grid
        columns={{ xs: 1, sm: 2 }}
        layout={{
          'run-manifest-input-cell-an-description': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id={INPUT_ID_RM_AN_DESCRIPTION}
                    label={INPUT_LABEL_RM_AN_DESCRIPTION}
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  INPUT_LABEL_RM_AN_DESCRIPTION,
                  () => {
                    setMessage(INPUT_ID_RM_AN_DESCRIPTION);
                  },
                  {
                    onFinishBatch: buildFinishInputTestBatchFunction(
                      INPUT_ID_RM_AN_DESCRIPTION,
                    ),
                  },
                  (message) => {
                    setMessage(INPUT_ID_RM_AN_DESCRIPTION, {
                      children: message,
                    });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(
                  INPUT_ID_RM_AN_DESCRIPTION,
                )}
                required
              />
            ),
            sm: 2,
          },
          'run-manifest-input-cell-an-password': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id={INPUT_ID_RM_AN_PASSWORD}
                    label={INPUT_LABEL_RM_AN_PASSWORD}
                    type={INPUT_TYPES.password}
                  />
                }
                inputTestBatch={buildPeacefulStringTestBatch(
                  INPUT_LABEL_RM_AN_PASSWORD,
                  () => {
                    setMessage(INPUT_ID_RM_AN_PASSWORD);
                  },
                  {
                    onFinishBatch: buildFinishInputTestBatchFunction(
                      INPUT_ID_RM_AN_PASSWORD,
                    ),
                  },
                  (message) => {
                    setMessage(INPUT_ID_RM_AN_PASSWORD, { children: message });
                  },
                )}
                onFirstRender={buildInputFirstRenderFunction(
                  INPUT_ID_RM_AN_PASSWORD,
                )}
                ref={passwordRef}
                required
              />
            ),
          },
          'run-manifest-input-cell-an-confirm-password': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    id={INPUT_ID_RM_AN_CONFIRM_PASSWORD}
                    label={INPUT_LABEL_RM_AN_CONFIRM_PASSWORD}
                    type={INPUT_TYPES.password}
                  />
                }
                required
                {...confirmPasswordProps}
              />
            ),
          },
        }}
        spacing="1em"
      />
      <Grid
        alignItems="center"
        columns={{ xs: hostListEntries.length + 1 }}
        layout={{
          ...hostHeaderRow,
          ...hostSelectRow,
          ...hostNewNameRow,
          ...hostNetworkRowList,
          ...hostFenceRowList,
          ...hostUpsRowList,
        }}
        columnSpacing="1em"
        rowSpacing="0.4em"
      />
      <Grid
        columns={{ xs: 2 }}
        layout={{
          ...defaultGatewayGridLayout,
          'run-manifest-dns-csv-cell-header': {
            children: <BodyText>DNS</BodyText>,
          },
          'run-manifest-dns-csv-cell': {
            children: <EndMono>{dnsCsv || MANIFEST_PARAM_NONE}</EndMono>,
          },
          'run-manifest-ntp-csv-cell-header': {
            children: <BodyText>NTP</BodyText>,
          },
          'run-manifest-ntp-csv-cell': {
            children: <EndMono>{ntpCsv || MANIFEST_PARAM_NONE}</EndMono>,
          },
        }}
        spacing="0.4em"
      />
    </FlexBox>
  );
};

export {
  INPUT_ID_RM_AN_CONFIRM_PASSWORD,
  INPUT_ID_RM_AN_DESCRIPTION,
  INPUT_ID_RM_AN_PASSWORD,
  buildInputIdRMHost,
};

export default RunManifestInputGroup;
