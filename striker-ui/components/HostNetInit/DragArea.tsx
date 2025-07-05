import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';

const PREFIX = 'DragArea';

const dragAreaClasses = {
  dragging: `${PREFIX}-dragging`,
};

const DragArea = styled(MuiBox)({
  position: 'relative',

  [`&.${dragAreaClasses.dragging}`]: {
    cursor: 'grabbing',
    userSelect: 'none',
  },
});

export { dragAreaClasses };

export default DragArea;
