import { FC } from 'react';
import {
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  iconButtonClasses as muiIconButtonClasses,
  inputClasses,
  Select as MUISelect,
  selectClasses as muiSelectClasses,
  SelectProps as MUISelectProps,
  InputAdornment as MUIInputAdornment,
  inputAdornmentClasses as muiInputAdornmentClasses,
} from '@mui/material';
import { Close as CloseIcon } from '@mui/icons-material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

type SelectOptionalProps = {
  onClearIndicatorClick?: MUIIconButtonProps['onClick'] | null;
};

type SelectProps = MUISelectProps & SelectOptionalProps;

const SELECT_DEFAULT_PROPS: Required<SelectOptionalProps> = {
  onClearIndicatorClick: null,
};

const Select: FC<SelectProps> = (selectProps) => {
  const {
    onClearIndicatorClick = SELECT_DEFAULT_PROPS.onClearIndicatorClick,
    ...muiSelectProps
  } = selectProps;
  const { children, sx } = muiSelectProps;
  const clearIndicator: JSX.Element | undefined = onClearIndicatorClick ? (
    <MUIInputAdornment position="end">
      <MUIIconButton onClick={onClearIndicatorClick}>
        <CloseIcon fontSize="small" />
      </MUIIconButton>
    </MUIInputAdornment>
  ) : undefined;

  const combinedSx = {
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

    ...sx,
  };

  return (
    <MUISelect
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        endAdornment: clearIndicator,
        ...muiSelectProps,
        sx: combinedSx,
      }}
    >
      {children}
    </MUISelect>
  );
};

Select.defaultProps = SELECT_DEFAULT_PROPS;

export type { SelectProps };

export default Select;
