import { FC } from 'react';
import { Box as MUIBox } from '@mui/material';

import StrikerInitForm from '../../components/StrikerInitForm';

const Init: FC = () => (
  <MUIBox
    sx={{
      display: 'flex',
      flexDirection: 'column',
    }}
  >
    <StrikerInitForm />
  </MUIBox>
);

export default Init;
