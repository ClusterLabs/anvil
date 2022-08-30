import { Box, Grid } from '@mui/material';
import { FC } from 'react';

import Header from '../../components/Header';

import {
  ComplexOperationsPanel,
  SimpleOperationsPanel,
} from '../../components/StrikerConfig';

const Config: FC = () => (
  <Box sx={{ display: 'flex', flexDirection: 'column' }}>
    <Header />
    <Grid container columns={{ xs: 1, md: 3, lg: 4 }}>
      <Grid item xs={1}>
        <SimpleOperationsPanel strikerHostName="STRIKER NAME" />
      </Grid>
      <Grid item md={2} xs={1}>
        <ComplexOperationsPanel />
      </Grid>
    </Grid>
  </Box>
);

export default Config;
