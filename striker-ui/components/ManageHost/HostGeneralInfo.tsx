import { Grid } from '@mui/material';
import { useMemo } from 'react';

import { BodyText, MonoText } from '../Text';

const HostGeneralInfo: React.FC<HostGeneralInfoProps> = (props) => {
  const { host } = props;

  const entries = useMemo<React.ReactElement[]>(
    () =>
      [
        {
          header: 'Name',
          value: host.name,
        },
        {
          header: 'UUID',
          value: host.uuid,
        },
        {
          header: 'Status',
          value: host.status.system,
        },
      ].map(({ header, value }) => (
        <Grid item key={`general-${header}`} width="100%">
          <Grid columnSpacing="1em" container>
            <Grid item width="10em">
              <BodyText>{header}</BodyText>
            </Grid>
            <Grid item xs>
              <MonoText>{value}</MonoText>
            </Grid>
          </Grid>
        </Grid>
      )),
    [host.name, host.status.system, host.uuid],
  );

  return (
    <Grid container rowSpacing="0.4em">
      {entries}
    </Grid>
  );
};

export default HostGeneralInfo;
