import { Grid } from '@mui/material';
import { FC } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';
import { REP_UUID } from '../../lib/consts/REG_EXP_PATTERNS';

import { BodyText, InlineMonoText, MonoText } from '../Text';

// This component requires a 2-column grid container as its parent.
const HostNetSummary = <Values extends HostNetInitFormikExtension>(
  ...[props]: Parameters<FC<HostNetSummaryProps<Values>>>
): ReturnType<FC<HostNetSummaryProps<Values>>> => {
  const { gatewayIface, ifaces, values } = props;

  return (
    <>
      <Grid item sx={{ marginTop: '1.4em' }} xs={2}>
        <BodyText>Networks</BodyText>
      </Grid>
      {Object.entries(values.networkInit.networks).map((net) => {
        const [netId, { interfaces, ip, sequence, subnetMask, type }] = net;

        const baseKey = `network-confirm-${netId}`;

        const label = (
          <BodyText>
            {NETWORK_TYPES[type]} {sequence} (
            <InlineMonoText>
              {`${type.toUpperCase()}${sequence}`}
            </InlineMonoText>
            )
          </BodyText>
        );

        if (!interfaces.some((value) => REP_UUID.test(value))) {
          return (
            <Grid key={baseKey} item mb="1.4em" xs={1}>
              {label}
              <BodyText>Incomplete, discard.</BodyText>
            </Grid>
          );
        }

        return (
          <Grid key={baseKey} item mb="1.4em" xs={1}>
            <Grid container spacing=".6em" columns={2}>
              <Grid item width="100%">
                {label}
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
