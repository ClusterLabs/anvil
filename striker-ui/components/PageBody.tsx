import { Grid } from '@mui/material';
import { FC } from 'react';

const PageBody: FC = (props) => {
  const { children } = props;

  return (
    <Grid columns={{ lg: 8, xs: 1 }} container>
      <Grid item xs={1} />
      <Grid item lg={6} xs={1}>
        {children}
      </Grid>
      <Grid item xs={1} />
    </Grid>
  );
};

export default PageBody;
