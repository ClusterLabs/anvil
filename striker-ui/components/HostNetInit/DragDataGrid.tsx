import { iconButtonClasses, styled } from '@mui/material';
import { DataGrid, gridClasses } from '@mui/x-data-grid';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'DragDataGrid';

const dragDataGridClasses = {
  draggable: `${PREFIX}-draggable`,
};

const DragDataGrid = styled(DataGrid)({
  color: GREY,

  [`& .${iconButtonClasses.root}`]: {
    color: 'inherit',
  },

  [`& .${gridClasses.cell}`]: {
    '&:focus': {
      outline: 'none',
    },

    '&:focus-within': {
      outline: 'none',
    },
  },

  [`& .${gridClasses.row}`]: {
    [`&.${dragDataGridClasses.draggable}:hover`]: {
      cursor: 'grab',

      [`& .${gridClasses.cell} p`]: {
        cursor: 'auto',
      },
    },
  },
});

export { dragDataGridClasses };

export default DragDataGrid;
