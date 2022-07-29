import {
  Visibility as MUIVisibilityIcon,
  VisibilityOff as MUIVisibilityOffIcon,
} from '@mui/icons-material';
import {
  IconButton as MUIIconButton,
  OutlinedInput as MUIOutlinedInput,
  outlinedInputClasses as muiOutlinedInputClasses,
  OutlinedInputProps as MUIOutlinedInputProps,
} from '@mui/material';
import { cloneElement, FC, ReactElement, useMemo, useState } from 'react';

import { GREY, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

type OutlinedInputProps = MUIOutlinedInputProps;

const INPUT_TYPES: Record<
  Exclude<MUIOutlinedInputProps['type'], undefined>,
  string
> = {
  password: 'password',
  text: 'text',
};

const OutlinedInput: FC<OutlinedInputProps> = (outlinedInputProps) => {
  const {
    endAdornment,
    label,
    sx,
    inputProps: { type: baseType, ...inputRestProps } = {},
    ...outlinedInputRestProps
  } = outlinedInputProps;

  const [type, setType] = useState<string>(baseType);

  const additionalEndAdornment = useMemo(
    () => (
      <>
        {baseType === INPUT_TYPES.password && (
          <MUIIconButton
            onClick={() => {
              setType((previous) =>
                previous === INPUT_TYPES.password
                  ? INPUT_TYPES.text
                  : INPUT_TYPES.password,
              );
            }}
          >
            {type === INPUT_TYPES.password ? (
              <MUIVisibilityIcon />
            ) : (
              <MUIVisibilityOffIcon />
            )}
          </MUIIconButton>
        )}
      </>
    ),
    [baseType, type],
  );
  const combinedSx = useMemo(
    () => ({
      color: GREY,

      [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
        borderColor: UNSELECTED,
      },

      '&:hover': {
        [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
          borderColor: GREY,
        },
      },

      [`&.${muiOutlinedInputClasses.focused}`]: {
        color: TEXT,

        [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
          borderColor: GREY,

          '& legend': {
            paddingRight: label ? '1.2em' : 0,
          },
        },
      },

      ...sx,
    }),
    [label, sx],
  );
  const combinedEndAdornment = useMemo(() => {
    let result;

    if (typeof endAdornment === 'object') {
      const casted = endAdornment as ReactElement;
      const {
        props: { children: castedChildren = [], ...castedRestProps },
      } = casted;

      return cloneElement(casted, {
        ...castedRestProps,
        children: (
          <>
            {additionalEndAdornment}
            {castedChildren}
          </>
        ),
      });
    }

    return result;
  }, [additionalEndAdornment, endAdornment]);

  return (
    <MUIOutlinedInput
      {...{
        endAdornment: combinedEndAdornment,
        label,
        inputProps: {
          type,
          ...inputRestProps,
        },
        ...outlinedInputRestProps,
        sx: combinedSx,
      }}
    />
  );
};

export type { OutlinedInputProps };

export default OutlinedInput;
