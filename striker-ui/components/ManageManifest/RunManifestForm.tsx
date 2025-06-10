import { Grid } from '@mui/material';
import { cloneDeep } from 'lodash';
import { useMemo } from 'react';

import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

import ActionGroup from '../ActionGroup';
import api from '../../lib/api';
import Checkbox from '../Checkbox';
import FlexBox from '../FlexBox';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import MessageBox from '../MessageBox';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import runManifestSchema from './runManifestSchema';
import SelectWithLabel from '../SelectWithLabel';
import { BodyText, MonoText, SmallText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const NONE = '--';

const RunManifestForm: React.FC<RunManifestFormProps> = (props) => {
  const {
    detail,
    knownFences,
    knownHosts,
    knownUpses,
    onSubmitSuccess,
    tools,
  } = props;

  const {
    anvil: existingAnvil,
    domain: manifestDomain,
    hostConfig,
    networkConfig,
  } = detail;

  const { hosts } = hostConfig;
  const { dnsCsv, networks, ntpCsv } = networkConfig;

  const hostEntries = useMemo(() => Object.entries(hosts), [hosts]);

  const networkEntries = useMemo(() => Object.entries(networks), [networks]);

  const knownFenceEntries = useMemo(
    () => Object.entries(knownFences),
    [knownFences],
  );

  const knownHostEntries = useMemo(
    () => Object.entries(knownHosts),
    [knownHosts],
  );

  const knownUpsEntries = useMemo(
    () => Object.entries(knownUpses),
    [knownUpses],
  );

  const hostOptions = useMemo(
    () =>
      knownHostEntries.map<SelectItem<string>>((entry) => {
        const [, { anvil, hostName, hostUUID }] = entry;

        return {
          displayValue: (
            <FlexBox spacing={0}>
              <BodyText inverted>{hostName}</BodyText>
              <SmallText inverted>
                {anvil ? `Used by ${anvil.name}` : `Ready`}
              </SmallText>
            </FlexBox>
          ),
          value: hostUUID,
        };
      }),
    [knownHostEntries],
  );

  const { disabledSubmit, formik, formikErrors, handleChange } =
    useFormikUtils<RunManifestFormikValues>({
      initialValues: {
        confirmPassword: '',
        description: '',
        hosts: hostEntries.reduce<RunManifestFormikValues['hosts']>(
          (previous, entry) => {
            const [hostId, { hostName: shortRenameTo, hostNumber, hostType }] =
              entry;

            let hostAnvil: RunManifestHostFormikValues['anvil'];
            let hostUuid = '';

            if (existingAnvil) {
              const {
                hosts: {
                  [hostNumber]: { uuid },
                },
              } = existingAnvil;

              hostUuid = uuid;

              const knownHost = knownHosts[uuid];

              if (knownHost) {
                hostAnvil = knownHost.anvil;
              }
            } else if (shortRenameTo) {
              const found = knownHostEntries.find(
                ([, { shortHostName }]) => shortHostName === shortRenameTo,
              );

              if (found) {
                const [, foundValue] = found;

                hostAnvil = foundValue.anvil;
                hostUuid = foundValue.hostUUID;
              }
            }

            previous[hostId] = {
              anvil: hostAnvil,
              number: hostNumber,
              type: hostType,
              uuid: hostUuid,
            };

            return previous;
          },
          {},
        ),
        password: '',
        rerun: Boolean(existingAnvil),
        reuseHosts: false,
      },
      onSubmit: (values, { setSubmitting }) => {
        const {
          confirmPassword,
          rerun,
          reuseHosts,
          hosts: hostSlots,
          ...restValues
        } = values;

        const summary = {
          ...(rerun ? null : restValues),
          hosts: Object.values(hostSlots).reduce<
            Record<
              string,
              {
                useHost: string;
                renameTo: string;
              }
            >
          >((previous, value) => {
            const { number, type, uuid } = value;

            const id = `${type}${number}`;

            const prettyId = `${type.replace('node', 'Subnode')} ${number}`;

            previous[prettyId] = {
              useHost: knownHosts[uuid].hostName,
              renameTo: `${hosts[id].hostName}.${manifestDomain}`,
            };

            return previous;
          }, {}),
        };

        tools.confirm.prepare({
          actionProceedText: 'Run',
          content: <FormSummary entries={summary} hasPassword />,
          onCancelAppend: () => setSubmitting(false),
          onProceedAppend: () => {
            tools.confirm.loading(true);

            api
              .put(`/command/run-manifest/${detail.uuid}`, values)
              .then(() => {
                tools.confirm.finish('Success', {
                  children: <>Successfully started installing {detail.name}</>,
                });

                onSubmitSuccess?.call(null);

                tools.edit.open(false);
              })
              .catch((error) => {
                const emsg = handleAPIError(error);

                emsg.children = (
                  <>Failed to run install manifest. {emsg.children}</>
                );

                tools.confirm.finish('Error', emsg);

                setSubmitting(false);
              });
          },
          titleText: `Run install manifest ${detail.name} with the following?`,
        });

        tools.confirm.open();
      },
      validationSchema: runManifestSchema,
    });

  const confirmPasswordChain = useMemo<string>(() => 'confirmPassword', []);
  const descriptionChain = useMemo<string>(() => 'description', []);
  const hostsChain = useMemo<string>(() => 'hosts', []);
  const passwordChain = useMemo<string>(() => 'password', []);
  const reuseHostsChain = useMemo<string>(() => 'reuseHosts', []);

  const hostSelectorRow = useMemo(
    () =>
      hostEntries.reduce<React.ReactNode[]>(
        (row, entry) => {
          const [hostId, { hostNumber, hostType }] = entry;

          const hostChain = `${hostsChain}.${hostId}`;
          const uuidChain = `${hostChain}.uuid`;

          const prettyId = `${hostType.replace(
            'node',
            'Subnode',
          )} ${hostNumber}`;

          // Selects don't require debounced validation, so don't make it
          // controlled by children.

          row.push(
            <Grid item key={`${hostId}-selector`} xs={1}>
              <SelectWithLabel<string>
                id={uuidChain}
                label={prettyId}
                name={uuidChain}
                onChange={(event) => {
                  const {
                    target: { value: uuid },
                  } = event;

                  const {
                    [uuid]: { anvil },
                  } = knownHosts;

                  const clonedHosts = cloneDeep(formik.values.hosts);

                  const value: RunManifestHostFormikValues = {
                    anvil,
                    number: hostNumber,
                    type: hostType,
                    uuid,
                  };

                  // Check whether the newly selected value is already used.
                  const duplicate = Object.entries<RunManifestHostFormikValues>(
                    clonedHosts,
                  ).find(([selectedHostId, { uuid: selectedHostUuid }]) => {
                    // Don't compare to self.
                    if (selectedHostId === hostId) return false;

                    return selectedHostUuid === uuid;
                  });

                  if (duplicate) {
                    const [duplicateId, duplicateValue] = duplicate;

                    const { number, type } = duplicateValue;

                    // Move the previously selected value to the duplicated
                    // slot, but don't replace the slot number and type.
                    clonedHosts[duplicateId] = {
                      ...clonedHosts[hostId],
                      number,
                      type,
                    };
                  }

                  // Set the newly selected value.
                  clonedHosts[hostId] = value;

                  return formik.setFieldValue(hostsChain, clonedHosts);
                }}
                required
                selectItems={hostOptions}
                selectProps={{
                  renderValue: (uuid) => {
                    const {
                      [uuid]: { hostName },
                    } = knownHosts;

                    return hostName;
                  },
                }}
                value={formik.values.hosts[hostId].uuid}
              />
            </Grid>,
          );

          return row;
        },
        [
          <Grid item key="host-selector-header" xs={1}>
            <BodyText>Use host</BodyText>
          </Grid>,
        ],
      ),
    [formik, hostEntries, hostOptions, hostsChain, knownHosts],
  );

  const hostRenameRow = useMemo(
    () =>
      hostEntries.reduce<React.ReactNode[]>(
        (row, entry) => {
          const [hostId, { hostName }] = entry;

          row.push(
            <Grid item key={`${hostId}-rename`} xs={1}>
              <MonoText noWrap>
                {hostName}.{manifestDomain}
              </MonoText>
            </Grid>,
          );

          return row;
        },
        [
          <Grid item key="host-rename-header" xs={1}>
            <BodyText>New hostname</BodyText>
          </Grid>,
        ],
      ),
    [hostEntries, manifestDomain],
  );

  const hostNetworkRows = useMemo(
    () =>
      networkEntries.reduce<React.ReactNode[]>((rows, entry) => {
        const [networkId, network] = entry;
        const { networkNumber, networkType } = network;

        const networkShortName = `${networkType.toLocaleUpperCase()}${networkNumber}`;

        const ips = hostEntries.map<React.ReactNode>((hostEntry) => {
          const [hostId, { networks: hostNetworks }] = hostEntry;

          const mk = (value = NONE) => (
            <Grid item key={`${networkId}-${hostId}-ip`} xs={1}>
              <MonoText>{value}</MonoText>
            </Grid>
          );

          if (!hostNetworks) return mk();

          const { [networkId]: hostNetwork } = hostNetworks;

          if (!hostNetwork) return mk();

          const { networkIp: hostIp } = hostNetwork;

          return mk(hostIp);
        });

        rows.push(
          <Grid item key={`${networkId}-header`} xs={1}>
            <BodyText>{networkShortName}</BodyText>
          </Grid>,
          ...ips,
        );

        return rows;
      }, []),
    [hostEntries, networkEntries],
  );

  const hostFenceRows = useMemo(
    () =>
      knownFenceEntries.reduce<React.ReactNode[]>((rows, entry) => {
        const [fenceId, fence] = entry;
        const { fenceName } = fence;

        const ports = hostEntries.map<React.ReactNode>((hostEntry) => {
          const [hostId, { fences: hostFences }] = hostEntry;

          const mk = (value = NONE) => (
            <Grid item key={`${fenceId}-${hostId}-port`} xs={1}>
              <MonoText>{value}</MonoText>
            </Grid>
          );

          if (!hostFences) return mk();

          const { [fenceName]: hostFence } = hostFences;

          if (!hostFence) return mk();

          const { fencePort } = hostFence;

          return mk(fencePort);
        });

        rows.push(
          <Grid item key={`${fenceId}-header`} xs={1}>
            <BodyText>Plug on {fenceName}</BodyText>
          </Grid>,
          ...ports,
        );

        return rows;
      }, []),
    [hostEntries, knownFenceEntries],
  );

  const hostUpsRows = useMemo(
    () =>
      knownUpsEntries.reduce<React.ReactNode[]>((rows, entry) => {
        const [upsId, ups] = entry;
        const { upsName } = ups;

        const uses = hostEntries.map<React.ReactNode>((hostEntry) => {
          const [hostId, { upses: hostUpses }] = hostEntry;

          const mk = (value = NONE) => (
            <Grid item key={`${upsId}-${hostId}-used`} xs={1}>
              <MonoText>{value}</MonoText>
            </Grid>
          );

          if (!hostUpses) return mk();

          const { [upsName]: hostUps } = hostUpses;

          if (!hostUps) return mk();

          const { isUsed: used } = hostUps;

          return mk(used ? 'yes' : 'no');
        });

        rows.push(
          <Grid item key={`${upsId}-header`} xs={1}>
            <BodyText>Uses {upsName}</BodyText>
          </Grid>,
          ...uses,
        );

        return rows;
      }, []),
    [hostEntries, knownUpsEntries],
  );

  const gatewayRow = useMemo(() => {
    const first = networkEntries.find((entry) => {
      const {
        1: { networkGateway },
      } = entry;

      return Boolean(networkGateway);
    });

    const mk = (value = NONE) => (
      <Grid item key="gateway-value" xs={1}>
        <MonoText justifyContent="end">{value}</MonoText>
      </Grid>
    );

    let value: React.ReactElement;

    if (first) {
      const [, { networkGateway }] = first;

      value =
        networkGateway && networkGateway.length > 0 ? mk(networkGateway) : mk();
    } else {
      value = mk();
    }

    return [
      <Grid item key="gateway-header" xs={1}>
        <BodyText>Gateway</BodyText>
      </Grid>,
      value,
    ];
  }, [networkEntries]);

  const dnsRow = useMemo(() => {
    const mk = (value = NONE) => (
      <Grid item key="dns-value" xs={1}>
        <MonoText justifyContent="end">{value}</MonoText>
      </Grid>
    );

    const value = dnsCsv && dnsCsv.length > 0 ? mk(dnsCsv) : mk();

    return [
      <Grid item key="dns-header" xs={1}>
        <BodyText>DNS</BodyText>
      </Grid>,
      value,
    ];
  }, [dnsCsv]);

  const ntpRow = useMemo(() => {
    const mk = (value = NONE) => (
      <Grid item key="ntp-value" xs={1}>
        <MonoText justifyContent="end">{value}</MonoText>
      </Grid>
    );

    const value = ntpCsv && ntpCsv.length > 0 ? mk(ntpCsv) : mk();

    return [
      <Grid item key="ntp-header" xs={1}>
        <BodyText>NTP</BodyText>
      </Grid>,
      value,
    ];
  }, [ntpCsv]);

  const reuseRow = useMemo<React.ReactNode>(() => {
    const selectedHosts = Object.values<RunManifestHostFormikValues>(
      formik.values.hosts,
    );

    const usedHosts = selectedHosts.filter((host) => Boolean(host.anvil));

    if (usedHosts.length === 0) return null;

    const usedHostsCsv = usedHosts
      .slice(1)
      .reduce<string>(
        (previous, host) =>
          `${previous}, ${knownHosts[host.uuid].shortHostName}`,
        knownHosts[usedHosts[0].uuid].shortHostName,
      );

    return (
      <Grid item width="100%">
        <MessageBox>
          <Checkbox
            id={reuseHostsChain}
            invert
            name={reuseHostsChain}
            onChange={formik.handleChange}
            required
            sx={{ marginRight: '.5em' }}
            thinPadding
            value={formik.values.reuseHosts}
          />
          Confirm reusing host(s): {usedHostsCsv}.
        </MessageBox>
      </Grid>
    );
  }, [formik, knownHosts, reuseHostsChain]);

  return (
    <Grid
      columns={{ xs: 1, sm: 2 }}
      component="form"
      container
      onSubmit={(event) => {
        event.preventDefault();
        formik.submitForm();
      }}
      spacing="1em"
    >
      {existingAnvil ? (
        <Grid item width="100%">
          <BodyText>Description</BodyText>
          <BodyText>{existingAnvil.description}</BodyText>
        </Grid>
      ) : (
        <>
          <Grid item width="100%">
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  id={descriptionChain}
                  label="Description"
                  name={descriptionChain}
                  onChange={handleChange}
                  required
                  value={formik.values.description}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={passwordChain}
                  label="Password"
                  name={passwordChain}
                  onChange={handleChange}
                  required
                  type={INPUT_TYPES.password}
                  value={formik.values.password}
                />
              }
            />
          </Grid>
          <Grid item xs={1}>
            <UncontrolledInput
              input={
                <OutlinedInputWithLabel
                  disableAutofill
                  id={confirmPasswordChain}
                  label="Confirm password"
                  name={confirmPasswordChain}
                  onChange={handleChange}
                  required
                  type={INPUT_TYPES.password}
                  value={formik.values.confirmPassword}
                />
              }
            />
          </Grid>
        </>
      )}
      <Grid item width="100%">
        <Grid
          alignItems="center"
          columns={hostEntries.length + 1}
          columnSpacing="1em"
          container
          rowSpacing=".6em"
        >
          {...hostSelectorRow}
          {...hostRenameRow}
          {...hostNetworkRows}
          {...hostFenceRows}
          {...hostUpsRows}
        </Grid>
      </Grid>
      <Grid item width="100%">
        <Grid columns={2} container spacing=".6em">
          {...gatewayRow}
          {...dnsRow}
          {...ntpRow}
        </Grid>
      </Grid>
      {reuseRow}
      <Grid item width="100%">
        <MessageGroup count={1} messages={formikErrors} />
      </Grid>
      <Grid item width="100%">
        <ActionGroup
          actions={[
            {
              background: 'blue',
              children: 'Run',
              disabled: disabledSubmit,
              type: 'submit',
            },
          ]}
        />
      </Grid>
    </Grid>
  );
};

export default RunManifestForm;
