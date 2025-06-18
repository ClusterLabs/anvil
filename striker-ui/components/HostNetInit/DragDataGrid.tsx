import muiIconButtonClasses from '@mui/material/IconButton/iconButtonClasses';
import styled from '@mui/material/styles/styled';
import { DataGrid as MuiDataGrid } from '@mui/x-data-grid/DataGrid/DataGrid';
import { gridClasses as muiDataGridClasses } from '@mui/x-data-grid/constants/gridClasses';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'DragDataGrid';

const dragDataGridClasses = {
  draggable: `${PREFIX}-draggable`,
};

const DragDataGrid = styled(MuiDataGrid)({
  color: GREY,

  [`.${muiDataGridClasses.columnHeader}`]: {
    '&:focus': {
      outline: 'none',
    },
  },

  [`.${muiDataGridClasses.columnHeaders}`]: {
    [`.${muiDataGridClasses['row--borderBottom']}`]: {
      backgroundColor: 'inherit',
    },
  },

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
