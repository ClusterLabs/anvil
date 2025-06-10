import { Grid } from '@mui/material';

import { HostNetSummary } from '../HostNetInit';
import { BodyText, MonoText } from '../Text';

const StrikerInitSummary: React.FC<StrikerInitSummaryProps> = (props) => {
  const { values } = props;

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
      <HostNetSummary {...props} />
    </Grid>
  );
};

export default StrikerInitSummary;
