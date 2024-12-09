import { Grid } from '@mui/material';
import { FC, useMemo } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';
import { REP_UUID } from '../../lib/consts/REG_EXP_PATTERNS';

import MessageBox from '../MessageBox';
import { BodyText, InlineMonoText, MonoText } from '../Text';

const getNetKey = (id: string) => `network-confirm-${id}`;

const getNetName = (type: string, seq: string) =>
  `${NETWORK_TYPES[type]} ${seq}`;

const getNetShort = (type: string, seq: string) =>
  `${type.toUpperCase()}${seq}`;

// This component requires a 2-column grid container as its parent.
const HostNetSummary = <Values extends HostNetInitFormikExtension>(
  ...[props]: Parameters<FC<HostNetSummaryProps<Values>>>
): ReturnType<FC<HostNetSummaryProps<Values>>> => {
  const { gatewayIface, ifaces, values } = props;

  const nets = useMemo(
    () => Object.entries<HostNetFormikValues>(values.networkInit.networks),
    [values.networkInit.networks],
  );

  const { hasIface, noIface } = useMemo(() => {
    const hasInterface: string[] = [];
    const noInterface: string[] = [];

    nets.forEach(([netId, net]) => {
      const { interfaces } = net;

      if (interfaces.some((value) => REP_UUID.test(value))) {
        hasInterface.push(netId);
      } else {
        noInterface.push(netId);
      }
    });

    return { hasIface: hasInterface, noIface: noInterface };
  }, [nets]);

  return (
    <>
      <Grid item sx={{ marginTop: '1.4em' }} xs={2}>
        <BodyText>Networks</BodyText>
      </Grid>
      {hasIface.map((netId) => {
        const { interfaces, ip, sequence, subnetMask, type } =
          values.networkInit.networks[netId];

        const baseKey = getNetKey(netId);
        const name = getNetName(type, sequence);
        const short = getNetShort(type, sequence);

        return (
          <Grid key={baseKey} item mb="1.4em" xs={1}>
            <Grid container spacing=".6em" columns={2}>
              <Grid item width="100%">
                <BodyText>
                  {name} (<InlineMonoText>{short}</InlineMonoText>)
                </BodyText>
              </Grid>
              {interfaces.map((ifaceUuid, ifaceIndex) => {
                let key = `${baseKey}-interface${ifaceIndex}`;
                let ifaceName = 'none';

                if (ifaceUuid !== '') {
                  key = `${key}-${ifaceUuid}`;
                  ifaceName = ifaces[ifaceUuid]?.name;
                }

                return (
                  <Grid columns={2} container key={key} item>
                    <Grid item xs={1}>
                      <BodyText>{`Link ${ifaceIndex + 1}`}</BodyText>
                    </Grid>
                    <Grid item xs={1}>
                      <MonoText>{ifaceName}</MonoText>
                    </Grid>
                  </Grid>
                );
              })}
              <Grid item width="100%">
                <MonoText>{`${ip}/${subnetMask}`}</MonoText>
              </Grid>
            </Grid>
          </Grid>
        );
      })}
      {noIface.map((netId, index, array) => {
        const { sequence, type } = values.networkInit.networks[netId];

        const key = getNetKey(netId);
        const name = getNetName(type, sequence);
        const short = getNetShort(type, sequence);

        const mb = index === array.length - 1 ? '1.4em' : '.2em';

        return (
          <Grid key={key} item mb={mb} width="100%">
            <MessageBox>
              No interface(s) set for {name} (
              <InlineMonoText inheritColour>{short}</InlineMonoText>), it will
              be discarded.
            </MessageBox>
          </Grid>
        );
      })}
      <Grid item width="100%" />
      <Grid item xs={1}>
        <BodyText>Gateway</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.networkInit.gateway}</MonoText>
      </Grid>
      <Grid item xs={1}>
        <BodyText>Gateway network</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{gatewayIface.toUpperCase()}</MonoText>
      </Grid>
      <Grid item xs={1}>
        <BodyText>Domain name server(s)</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.networkInit.dns}</MonoText>
      </Grid>
    </>
  );
};

export default HostNetSummary;
