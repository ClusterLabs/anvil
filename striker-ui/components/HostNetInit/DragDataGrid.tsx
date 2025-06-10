import {
  iconButtonClasses as muiIconButtonClasses,
  styled,
} from '@mui/material';
import {
  DataGrid as MuiDataGrid,
  gridClasses as muiDataGridClasses,
} from '@mui/x-data-grid';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'DragDataGrid';

const dragDataGridClasses = {
  draggable: `${PREFIX}-draggable`,
};

const DragDataGrid = styled(MuiDataGrid)({
  color: GREY,

  [`& .${muiIconButtonClasses.root}`]: {
    color: 'inherit',
  },

  [`& .${muiDataGridClasses.cell}`]: {
    '&:focus': {
      outline: 'none',
    },

    '&:focus-within': {
      outline: 'none',
    },
  },

  [`& .${muiDataGridClasses.row}`]: {
    [`&.${dragDataGridClasses.draggable}:hover`]: {
      cursor: 'grab',

      [`& .${muiDataGridClasses.cell} p`]: {
        cursor: 'auto',
      },
    },
  },
}) as typeof MuiDataGrid;

export { dragDataGridClasses };

export default DragDataGrid;
