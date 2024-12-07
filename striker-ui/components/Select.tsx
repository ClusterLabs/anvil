import { Close as CloseIcon } from '@mui/icons-material';
import {
  IconButton as MUIIconButton,
  iconButtonClasses as muiIconButtonClasses,
  inputClasses,
  Select as MUISelect,
  selectClasses as muiSelectClasses,
  InputAdornment as MUIInputAdornment,
  inputAdornmentClasses as muiInputAdornmentClasses,
} from '@mui/material';
import { FC, useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

const Select = <Value = string,>(
  ...[props]: Parameters<FC<SelectProps<Value>>>
) => {
  const { onClearIndicatorClick, ...muiSelectProps } = props;
  const { sx: selectSx, value, ...restMuiSelectProps } = muiSelectProps;

  const combinedSx = useMemo(
    () => ({
      [`& .${muiSelectClasses.icon}`]: {
        color: GREY,
      },

      [`& .${muiInputAdornmentClasses.root}`]: {
        marginRight: '.8em',
      },

      [`& .${muiIconButtonClasses.root}`]: {
        color: GREY,
        visibility: 'hidden',
      },

      [`&:hover .${muiInputAdornmentClasses.root} .${muiIconButtonClasses.root},
      &.${inputClasses.focused} .${muiInputAdornmentClasses.root} .${muiIconButtonClasses.root}`]:
        {
          visibility: 'visible',
        },

      ...selectSx,
    }),
    [selectSx],
  );

  const clearIndicatorElement = useMemo<React.ReactNode>(() => {
    if (!value || !onClearIndicatorClick) return undefined;

    return (
      <MUIInputAdornment position="end">
        <MUIIconButton onClick={onClearIndicatorClick} tabIndex={-1}>
          <CloseIcon fontSize="small" />
        </MUIIconButton>
      </MUIInputAdornment>
    );
  }, [onClearIndicatorClick, value]);

  return (
    <MUISelect<Value>
      endAdornment={clearIndicatorElement}
      value={value}
      {...restMuiSelectProps}
      sx={combinedSx}
    />
  );
};

export default Select;
