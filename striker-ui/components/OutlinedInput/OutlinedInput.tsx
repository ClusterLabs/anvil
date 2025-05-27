import {
  Visibility as MuiVisibilityIcon,
  VisibilityOff as MuiVisibilityOffIcon,
} from '@mui/icons-material';
import {
  IconButton as MuiIconButton,
  IconButtonProps as MuiIconButtonProps,
  OutlinedInput as MuiOutlinedInput,
  outlinedInputClasses as muiOutlinedInputClasses,
  OutlinedInputProps as MuiOutlinedInputProps,
} from '@mui/material';
import { merge } from 'lodash';
import { cloneElement, useMemo, useState } from 'react';

import { GREY, PURPLE, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';
import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

type OutlinedInputOptionalProps = {
  disableAutofill?: boolean;
  onPasswordVisibilityAppend?: (
    inputType: string,
    ...restArgs: Parameters<Exclude<MuiIconButtonProps['onClick'], undefined>>
  ) => void;
};

type OutlinedInputProps = MuiOutlinedInputProps & OutlinedInputOptionalProps;

const OutlinedInput: React.FC<OutlinedInputProps> = (props) => {
  const {
    disableAutofill = false,
    endAdornment,
    inputProps: { type: baseType, ...inputRestProps } = {},
    label,
    onPasswordVisibilityAppend,
    sx,
    // Input props that depend on other input props.
    type: initialType = baseType,

    ...restProps
  } = props;

  const { required, value } = props;

  const [type, setType] = useState<string>(initialType);

  const passwordVisibilityButton = useMemo(() => {
    const isInitialTypePassword = initialType === INPUT_TYPES.password;
    const isTypePassword = type === INPUT_TYPES.password;

    return (
      <>
        {isInitialTypePassword && (
          <MuiIconButton
            onClick={(...args) => {
              const newType = isTypePassword
                ? INPUT_TYPES.text
                : INPUT_TYPES.password;

              setType(newType);
              onPasswordVisibilityAppend?.call(null, newType, ...args);
            }}
          >
            {isTypePassword ? <MuiVisibilityIcon /> : <MuiVisibilityOffIcon />}
          </MuiIconButton>
        )}
      </>
    );
  }, [initialType, onPasswordVisibilityAppend, type]);

  const mergedSx = useMemo(() => {
    const remind = required && !value;

    return merge(
      {
        color: GREY,

        [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
          borderColor: remind ? PURPLE : UNSELECTED,
        },

        [`& .${muiOutlinedInputClasses.input}`]: {
          color: TEXT,
          margin: '10px 8.5px',
          marginRight: '0',
          padding: '6.5px 5.5px',
          paddingRight: '0',
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
      },
      sx,
    );
  }, [label, required, sx, value]);

  const combinedEndAdornment = useMemo(() => {
    let result;

    if (typeof endAdornment === 'object') {
      const casted = endAdornment as React.ReactElement;
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

  const autofillLock = useMemo<
    Pick<MuiOutlinedInputProps, 'onFocus' | 'readOnly'> | undefined
  >(
    () =>
      disableAutofill
        ? {
            onFocus: (...args) => {
              const [event] = args;

              event.target.readOnly = false;

              restProps?.onFocus?.call(null, ...args);
            },
            readOnly: true,
          }
        : undefined,
    [disableAutofill, restProps?.onFocus],
  );

  return (
    <MuiOutlinedInput
      endAdornment={combinedEndAdornment}
      label={label}
      inputProps={{ type, ...inputRestProps }}
      {...restProps}
      {...autofillLock}
      sx={mergedSx}
    />
  );
};

export type { OutlinedInputProps };

export default OutlinedInput;
