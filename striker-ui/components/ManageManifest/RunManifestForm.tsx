import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import MessageGroup from '../MessageGroup';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import SelectWithLabel from '../SelectWithLabel';
import { BodyText, MonoText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import useFormikUtils from '../../hooks/useFormikUtils';

const NONE = '--';

const RunManifestForm: FC<RunManifestFormProps> = (props) => {
  const { detail, knownFences, knownHosts, knownUpses } = props;

  const { domain: manifestDomain, hostConfig, networkConfig } = detail;
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
      knownHostEntries.map<SelectItem<RunManifestHostFormikValues>>((entry) => {
        const [, host] = entry;
        const { anvil, hostName, hostType, hostUUID } = host;

        return {
          displayValue: hostName,
          value: {
            anvil,
            type: hostType,
            uuid: hostUUID,
          },
        };
      }),
    [knownHostEntries],
  );

  const { disabledSubmit, formik, formikErrors, handleChange } =
    useFormikUtils<RunManifestFormikValues>({
      initialValues: {
        confirmPassword: '',
        description: '',
        hosts: {},
        password: '',
      },
      onSubmit: (values, { setSubmitting }) => {
        setSubmitting(false);
      },
    });

  const confirmPasswordChain = useMemo<string>(() => 'confirmPassword', []);
  const descriptionChain = useMemo<string>(() => 'description', []);
  const hostsChain = useMemo<string>(() => 'hosts', []);
  const passwordChain = useMemo<string>(() => 'password', []);

  const hostHeaderRow = useMemo(
    () =>
      hostEntries.reduce<React.ReactNode[]>(
        (row, entry) => {
          const [hostId, { hostType, hostNumber }] = entry;

          const prettyId = `${hostType.replace(
            'node',
            'subnode',
          )} ${hostNumber}`;

          row.push(
            <Grid item key={`${hostId}-header`} xs={1}>
              <BodyText>{prettyId}</BodyText>
            </Grid>,
          );

          return row;
        },
        [<Grid item key="host-header-offset" xs={1} />],
      ),
    [hostEntries],
  );

  const hostSelectorRow = useMemo(
    () =>
      hostEntries.reduce<React.ReactNode[]>(
        (row, entry) => {
          const [hostId, { hostNumber }] = entry;

          const hostChain = `${hostsChain}.${hostNumber}`;

          row.push(
            <Grid item key={`${hostId}-selector`} xs={1}>
              <UncontrolledInput
                input={
                  <SelectWithLabel<RunManifestHostFormikValues>
                    id={hostChain}
                    name={hostChain}
                    onChange={formik.handleChange}
                    required
                    selectItems={hostOptions}
                    value={formik.values.hosts[hostNumber]}
                  />
                }
              />
            </Grid>,
          );

          return row;
        },
        [
          <Grid item key="host-selector-header" xs={1}>
            Use host
          </Grid>,
        ],
      ),
    [
      formik.handleChange,
      formik.values.hosts,
      hostEntries,
      hostOptions,
      hostsChain,
    ],
  );

  const hostRenameRow = useMemo(
    () =>
      hostEntries.reduce<React.ReactNode[]>(
        (row, entry) => {
          const [hostId, { hostName }] = entry;

          row.push(
            <Grid item key={`${hostId}-rename`} xs={1}>
              <BodyText>
                {hostName}.{manifestDomain}
              </BodyText>
            </Grid>,
          );

          return row;
        },
        [
          <Grid item key="host-rename-header" xs={1}>
            New hostname
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
            <BodyText>Port on {fenceName}</BodyText>
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
        <MonoText>{value}</MonoText>
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
        <MonoText>{value}</MonoText>
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
        <MonoText>{value}</MonoText>
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
              id={passwordChain}
              label="Password"
              name={passwordChain}
              onChange={handleChange}
              required
              value={formik.values.password}
            />
          }
        />
      </Grid>
      <Grid item xs={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={confirmPasswordChain}
              label="Confirm password"
              name={confirmPasswordChain}
              onChange={handleChange}
              required
              value={formik.values.confirmPassword}
            />
          }
        />
      </Grid>
      <Grid item width="100%">
        <Grid
          alignItems="center"
          columns={hostEntries.length + 1}
          columnSpacing="1em"
          container
          rowSpacing=".4em"
        >
          {...hostHeaderRow}
          {...hostSelectorRow}
          {...hostRenameRow}
          {...hostNetworkRows}
          {...hostFenceRows}
          {...hostUpsRows}
        </Grid>
      </Grid>
      <Grid item width="100%">
        <Grid columns={2} container spacing=".4em">
          {...gatewayRow}
          {...dnsRow}
          {...ntpRow}
        </Grid>
      </Grid>
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
