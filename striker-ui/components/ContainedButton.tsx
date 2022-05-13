import {
  Button as MUIButton,
  ButtonProps as MUIButtonProps,
} from '@mui/material';

import { BLACK, GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

type ContainedButtonProps = MUIButtonProps;

const ContainedButton = (
  containedButtonProps: ContainedButtonProps,
): JSX.Element => {
  const { children, sx } = containedButtonProps;
  const combinedSx: ContainedButtonProps['sx'] = {
    backgroundColor: TEXT,
    color: BLACK,
    textTransform: 'none',

    '&:hover': {
      backgroundColor: GREY,
    },

    ...sx,
  };

  return (
    <MUIButton
      {...{
        variant: 'contained',
        ...containedButtonProps,
        sx: combinedSx,
      }}
    >
      {children}
    </MUIButton>
  );
};

export type { ContainedButtonProps };

export default ContainedButton;
