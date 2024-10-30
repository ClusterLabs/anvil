import { styled } from '@mui/material';
import { gridClasses } from '@mui/x-data-grid';

import { BLUE, GREY } from '../../lib/consts/DEFAULT_THEME';

import DragDataGrid from '../HostNetInit/DragDataGrid';

const SelectDataGrid = styled(DragDataGrid)({
  [`& .${gridClasses.row}`]: {
    [`.${gridClasses.cell}:first-child`]: {
      borderLeft: `thick solid ${GREY}`,
    },

    [`&.Mui-selected`]: {
      [`.${gridClasses.cell}:first-child`]: {
        borderLeft: `thick solid ${BLUE}`,
      },
    },
  },
});

export default SelectDataGrid;
