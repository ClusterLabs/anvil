import { Grid } from '@mui/material';
import { FC } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import { BodyText, InlineMonoText, MonoText } from '../Text';

const StrikerInitSummary: FC<StrikerInitSummaryProps> = (props) => {
  const { gatewayIface, ifaces, values } = props;

  return (
    <Grid container spacing=".6em" columns={{ xs: 2 }}>
      <Grid item xs={1}>
        <BodyText>Organization name</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.organizationName}</MonoText>
      </Grid>
      <Grid item xs={1}>
        <BodyText>Organization prefix</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.organizationPrefix}</MonoText>
      </Grid>
      <Grid item xs={1}>
        <BodyText>Striker number</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.hostNumber}</MonoText>
      </Grid>
      <Grid item xs={1}>
        <BodyText>Domain name</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.domainName}</MonoText>
      </Grid>
      <Grid item xs={1}>
        <BodyText>Host name</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.hostName}</MonoText>
      </Grid>
      <Grid item sx={{ marginTop: '1.4em' }} xs={2}>
        <BodyText>Networks</BodyText>
      </Grid>
      {Object.entries(values.networkInit.networks).map((net) => {
        const [netId, { interfaces, ip, sequence, subnetMask, type }] = net;

        return (
          <Grid key={`network-confirm-${netId}`} item xs={1}>
            <Grid container spacing=".6em" columns={{ xs: 2 }}>
              <Grid item xs={2}>
                <BodyText>
                  {NETWORK_TYPES[type]} {sequence} (
                  <InlineMonoText>
                    {`${type.toUpperCase()}${sequence}`}
                  </InlineMonoText>
                  )
                </BodyText>
              </Grid>
              {interfaces.map((ifaceUuid, ifaceIndex) => {
                let key = `network-confirm-${netId}-interface${ifaceIndex}`;
                let ifaceName = 'none';

                if (ifaceUuid !== '') {
                  key = `${key}-${ifaceUuid}`;
                  ifaceName = ifaces[ifaceUuid]?.name;
                }

                return (
                  <Grid columns={{ xs: 2 }} container key={key} item>
                    <Grid item xs={1}>
                      <BodyText>{`Link ${ifaceIndex + 1}`}</BodyText>
                    </Grid>
                    <Grid item xs={1}>
                      <MonoText>{ifaceName}</MonoText>
                    </Grid>
                  </Grid>
                );
              })}
              <Grid item xs={2}>
                <MonoText>{`${ip}/${subnetMask}`}</MonoText>
              </Grid>
            </Grid>
          </Grid>
        );
      })}
      <Grid item sx={{ marginBottom: '1.4em' }} xs={2} />
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
    </Grid>
  );
};

export default StrikerInitSummary;
