import { Box as MuiBox, styled } from '@mui/material';

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
