import { iconButtonClasses, styled } from '@mui/material';
import {
  DataGrid as MuiDataGrid,
  gridClasses as muiGridClasses,
} from '@mui/x-data-grid';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'DragDataGrid';

const dragDataGridClasses = {
  draggable: `${PREFIX}-draggable`,
};

const DragDataGrid = styled(MuiDataGrid)({
  color: GREY,

  [`& .${iconButtonClasses.root}`]: {
    color: 'inherit',
  },

  [`& .${muiGridClasses.cell}`]: {
    '&:focus': {
      outline: 'none',
    },

    '&:focus-within': {
      outline: 'none',
    },
  },

  [`& .${muiGridClasses.row}`]: {
    [`&.${dragDataGridClasses.draggable}:hover`]: {
      cursor: 'grab',

      [`& .${muiGridClasses.cell} p`]: {
        cursor: 'auto',
      },
    },
  },
}) as typeof MuiDataGrid;

export { dragDataGridClasses };

export default DragDataGrid;
