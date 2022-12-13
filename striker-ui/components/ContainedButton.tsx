import { Button as MUIButton, SxProps, Theme } from '@mui/material';
import { FC, useMemo } from 'react';

import { BLACK, GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

const ContainedButton: FC<ContainedButtonProps> = ({ sx, ...restProps }) => {
  const combinedSx = useMemo<SxProps<Theme>>(
    () => ({
      backgroundColor: TEXT,
      color: BLACK,
      textTransform: 'none',

      '&:hover': {
        backgroundColor: GREY,
      },

      ...sx,
    }),
    [sx],
  );

  return (
    <MUIButton
      {...{
        variant: 'contained',
        ...restProps,
        sx: combinedSx,
      }}
    />
  );
};

export default ContainedButton;
