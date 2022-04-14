import {
  Select as MUISelect,
  selectClasses as muiSelectClasses,
  SelectProps as MUISelectProps,
} from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

type SelectProps = MUISelectProps;

const Select = (selectProps: SelectProps): JSX.Element => {
  const { children, sx } = selectProps;
  const combinedSx = {
    [`& .${muiSelectClasses.icon}`]: {
      color: GREY,
    },

    ...sx,
  };

  return (
    <MUISelect
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        ...selectProps,
        sx: combinedSx,
      }}
    >
      {children}
    </MUISelect>
  );
};

export type { SelectProps };

export default Select;
