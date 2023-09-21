import {
  Button as MuiButton,
  buttonClasses as muiButtonClasses,
  styled,
} from '@mui/material';
import { FC } from 'react';

import {
  BLACK,
  BLUE,
  DISABLED,
  GREY,
  RED,
  TEXT,
} from '../lib/consts/DEFAULT_THEME';

const MAP_TO_COLOUR: Record<ContainedButtonBackground, string> = {
  blue: BLUE,
  normal: GREY,
  red: RED,
};

const BaseStyle = styled(MuiButton)({
  backgroundColor: GREY,
  color: BLACK,
  textTransform: 'none',

  '&:hover': {
    backgroundColor: `${GREY}F0`,
  },

  [`&.${muiButtonClasses.disabled}`]: {
    backgroundColor: DISABLED,
  },
});

const Base: FC<ContainedButtonProps> = (props) => (
  <BaseStyle variant="contained" {...props} />
);

const ContainedButton = styled(Base)((props) => {
  const { background = 'normal' } = props;

  let bg: string | undefined;
  let color: string | undefined;

  if (background !== 'normal') {
    bg = MAP_TO_COLOUR[background];
    color = TEXT;
  }

  return {
    backgroundColor: bg,
    color,

    '&:hover': {
      backgroundColor: `${bg}F0`,
    },
  };
});

export default ContainedButton;
