import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';

import { BLUE, GREY } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'IfaceDragHandle';

const ifaceDragHandleClasses = {
  applied: `${PREFIX}-applied`,
};

const IfaceDragHandle = styled(MuiBox)({
  alignItems: 'center',
  display: 'flex',
  flexDirection: 'row',

  '&:hover': {
    cursor: 'grab',
  },

  '& > svg': {
    color: GREY,
  },

  [`&.${ifaceDragHandleClasses.applied}`]: {
    '&:hover': {
      cursor: 'auto',
    },

    '& > svg': {
      color: BLUE,
    },
  },
});

export { ifaceDragHandleClasses };

export default IfaceDragHandle;
