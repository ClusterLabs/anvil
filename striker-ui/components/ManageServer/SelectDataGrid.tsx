import styled from '@mui/material/styles/styled';
import { DataGrid as MuiDataGrid } from '@mui/x-data-grid/DataGrid';
import { gridClasses as muiDataGridClasses } from '@mui/x-data-grid/constants/gridClasses';

import { BLUE, GREY } from '../../lib/consts/DEFAULT_THEME';

import DragDataGrid from '../HostNetInit/DragDataGrid';

const SelectDataGrid = styled(DragDataGrid)({
  [`& .${muiDataGridClasses.cell}`]: {
    '&[data-colindex="0"]': {
      borderLeft: `thick solid ${GREY}`,
    },
  },

  [`& .${muiDataGridClasses.row}`]: {
    '&:hover': {
      cursor: 'pointer',
    },
  },

  [`& .Mui-selected`]: {
    [`& .${muiDataGridClasses.cell}`]: {
      '&[data-colindex="0"]': {
        borderLeft: `thick solid ${BLUE}`,
      },
    },
  },
}) as typeof MuiDataGrid;

export default SelectDataGrid;
