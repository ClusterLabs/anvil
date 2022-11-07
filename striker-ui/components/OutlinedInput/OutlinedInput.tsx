import {
  Visibility as MUIVisibilityIcon,
  VisibilityOff as MUIVisibilityOffIcon,
} from '@mui/icons-material';
import {
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  OutlinedInput as MUIOutlinedInput,
  outlinedInputClasses as muiOutlinedInputClasses,
  OutlinedInputProps as MUIOutlinedInputProps,
} from '@mui/material';
import { cloneElement, FC, ReactElement, useMemo, useState } from 'react';

import { GREY, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';
import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

type OutlinedInputOptionalProps = {
  onPasswordVisibilityAppend?: (
    inputType: string,
    ...restArgs: Parameters<Exclude<MUIIconButtonProps['onClick'], undefined>>
  ) => void;
};

type OutlinedInputProps = MUIOutlinedInputProps & OutlinedInputOptionalProps;

const OUTLINED_INPUT_DEFAULT_PROPS: Pick<
  OutlinedInputOptionalProps,
  'onPasswordVisibilityAppend'
> = {
  onPasswordVisibilityAppend: undefined,
};

const OutlinedInput: FC<OutlinedInputProps> = (outlinedInputProps) => {
  const {
    endAdornment,
    label,
    onPasswordVisibilityAppend,
    sx,
    inputProps: { type: baseType, ...inputRestProps } = {},
    // Input props that depend on other input props.
    type: initialType = baseType,

    ...outlinedInputRestProps
  } = outlinedInputProps;

  const [type, setType] = useState<string>(initialType);

  const passwordVisibilityButton = useMemo(() => {
    const isInitialTypePassword = initialType === INPUT_TYPES.password;
    const isTypePassword = type === INPUT_TYPES.password;

    return (
      <>
        {isInitialTypePassword && (
          <MUIIconButton
            onClick={(...args) => {
              const newType = isTypePassword
                ? INPUT_TYPES.text
                : INPUT_TYPES.password;

              setType(newType);
              onPasswordVisibilityAppend?.call(null, newType, ...args);
            }}
          >
            {isTypePassword ? <MUIVisibilityIcon /> : <MUIVisibilityOffIcon />}
          </MUIIconButton>
        )}
      </>
    );
  }, [initialType, onPasswordVisibilityAppend, type]);
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

      result = cloneElement(casted, {
        ...castedRestProps,
        children: (
          <>
            {passwordVisibilityButton}
            {castedChildren}
          </>
        ),
      });
    }

    return result;
  }, [passwordVisibilityButton, endAdornment]);

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

OutlinedInput.defaultProps = OUTLINED_INPUT_DEFAULT_PROPS;

export type { OutlinedInputProps };

export default OutlinedInput;
