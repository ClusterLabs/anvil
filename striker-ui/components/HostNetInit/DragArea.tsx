import { Box, styled } from '@mui/material';

const PREFIX = 'DragArea';

const dragAreaClasses = {
  dragging: `${PREFIX}-dragging`,
};

const DragArea = styled(Box)({
  position: 'relative',

  [`&.${dragAreaClasses.dragging}`]: {
    cursor: 'grabbing',
    userSelect: 'none',
  },
});

export { dragAreaClasses };

export default DragArea;
