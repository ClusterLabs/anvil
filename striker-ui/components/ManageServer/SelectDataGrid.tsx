import { styled } from '@mui/material';
import { gridClasses as muiDataGridClasses } from '@mui/x-data-grid';

import { BLUE, GREY } from '../../lib/consts/DEFAULT_THEME';

import DragDataGrid from '../HostNetInit/DragDataGrid';

const SelectDataGrid = styled(DragDataGrid)({
  [`& .${muiDataGridClasses.row}`]: {
    '&:hover': {
      cursor: 'pointer',
    },

    [`&.Mui-selected`]: {
      [`.${muiDataGridClasses.cell}:first-child`]: {
        borderLeft: `thick solid ${BLUE}`,
      },
    },

    [`.${muiDataGridClasses.cell}:first-child`]: {
      borderLeft: `thick solid ${GREY}`,
    },
  },
}) as typeof DragDataGrid;

export default SelectDataGrid;
