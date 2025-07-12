import muiIconButtonClasses from '@mui/material/IconButton/iconButtonClasses';
import muiTypographyClasses from '@mui/material/Typography/typographyClasses';
import styled from '@mui/material/styles/styled';
import { DataGrid as MuiDataGrid } from '@mui/x-data-grid/DataGrid';
import { gridClasses as muiDataGridClasses } from '@mui/x-data-grid/constants/gridClasses';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'DragDataGrid';

const dragDataGridClasses = {
  draggable: `${PREFIX}-draggable`,
};

const DragDataGrid = styled(MuiDataGrid)({
  color: GREY,

  [`& .${dragDataGridClasses.draggable}`]: {
    '&:hover': {
      cursor: 'grab',

      [`& .${muiDataGridClasses.cell}`]: {
        [`& .${muiTypographyClasses.root}`]: {
          cursor: 'auto',
        },
      },
    },
  },

  [`& .${muiDataGridClasses.columnHeader}`]: {
    '&:focus': {
      outline: 'none',
    },
  },

  [`& .${muiDataGridClasses.cell}`]: {
    '&:focus': {
      outline: 'none',
    },

    '&:focus-within': {
      outline: 'none',
    },
  },

  [`& .${muiDataGridClasses['container--top']}`]: {
    '& [role="row"]': {
      backgroundColor: 'transparent',
    },
  },

  [`& .${muiIconButtonClasses.root}`]: {
    color: 'inherit',
  },
}) as typeof MuiDataGrid;

export { dragDataGridClasses };

export default DragDataGrid;
