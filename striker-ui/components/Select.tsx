import { Close as MuiCloseIcon } from '@mui/icons-material';
import {
  IconButton as MuiIconButton,
  iconButtonClasses as muiIconButtonClasses,
  inputClasses as muiInputClasses,
  Select as MuiSelect,
  selectClasses as muiSelectClasses,
  InputAdornment as MuiInputAdornment,
  inputAdornmentClasses as muiInputAdornmentClasses,
} from '@mui/material';
import { useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

const Select = <Value = string,>(
  ...[props]: Parameters<React.FC<SelectProps<Value>>>
): ReturnType<React.FC<SelectProps<Value>>> => {
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
      &.${muiInputClasses.focused} .${muiInputAdornmentClasses.root} .${muiIconButtonClasses.root}`]:
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
      <MuiInputAdornment position="end">
        <MuiIconButton onClick={onClearIndicatorClick} tabIndex={-1}>
          <MuiCloseIcon fontSize="small" />
        </MuiIconButton>
      </MuiInputAdornment>
    );
  }, [onClearIndicatorClick, value]);

  return (
    <MuiSelect<Value>
      endAdornment={clearIndicatorElement}
      value={value}
      {...restMuiSelectProps}
      sx={combinedSx}
    />
  );
};

export default Select;
