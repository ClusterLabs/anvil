import { Grid } from '@mui/material';
import { FC } from 'react';

import ContainedButton from '../ContainedButton';
import { BodyText } from '../Text';

const ServerMigration: FC<ServerMigrationProps> = (props) => {
  const { detail } = props;

  return (
    <Grid container spacing="1em">
      <Grid item width="100%">
        <BodyText>Running on: {detail.host.short}</BodyText>
      </Grid>
      <Grid item>
        <ContainedButton>Migrate</ContainedButton>
      </Grid>
    </Grid>
  );
};

export default ServerMigration;
