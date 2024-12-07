import { Grid } from '@mui/material';
import { FC } from 'react';

import { HostNetSummary } from '../HostNetInit';
import { BodyText, MonoText } from '../Text';

const PrepareHostNetworkSummary: FC<PrepareHostNetworkSummaryProps> = (
  props,
) => {
  const { values } = props;

  return (
    <Grid container spacing=".6em" columns={{ xs: 2 }}>
      <Grid item xs={1}>
        <BodyText>Host name</BodyText>
      </Grid>
      <Grid item xs={1}>
        <MonoText>{values.hostName}</MonoText>
      </Grid>
      <HostNetSummary {...props} />
    </Grid>
  );
};

export default PrepareHostNetworkSummary;
