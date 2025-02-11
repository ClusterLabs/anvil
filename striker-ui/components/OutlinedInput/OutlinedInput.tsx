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
import { merge } from 'lodash';
import { cloneElement, FC, ReactElement, useMemo, useState } from 'react';

import { GREY, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';
import INPUT_TYPES from '../../lib/consts/INPUT_TYPES';

type OutlinedInputOptionalProps = {
  disableAutofill?: boolean;
  onPasswordVisibilityAppend?: (
    inputType: string,
    ...restArgs: Parameters<Exclude<MUIIconButtonProps['onClick'], undefined>>
  ) => void;
};

type OutlinedInputProps = MUIOutlinedInputProps & OutlinedInputOptionalProps;

const OUTLINED_INPUT_DEFAULT_PROPS: Pick<
  OutlinedInputOptionalProps,
  'disableAutofill' | 'onPasswordVisibilityAppend'
> = {
  disableAutofill: false,
  onPasswordVisibilityAppend: undefined,
};

const OutlinedInput: FC<OutlinedInputProps> = (outlinedInputProps) => {
  const {
    disableAutofill = false,
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
    () =>
      merge(
        {
          color: GREY,

          [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
            borderColor: UNSELECTED,
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
      ),
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

  const autofillLock = useMemo<
    Pick<MUIOutlinedInputProps, 'onFocus' | 'readOnly'> | undefined
  >(
    () =>
      disableAutofill
        ? {
            onFocus: (...args) => {
              const [event] = args;

              event.target.readOnly = false;

              outlinedInputRestProps?.onFocus?.call(null, ...args);
            },
            readOnly: true,
          }
        : undefined,
    [disableAutofill, outlinedInputRestProps?.onFocus],
  );

  return (
    <MUIOutlinedInput
      endAdornment={combinedEndAdornment}
      label={label}
      inputProps={{ type, ...inputRestProps }}
      {...outlinedInputRestProps}
      {...autofillLock}
      sx={combinedSx}
    />
  );
};

OutlinedInput.defaultProps = OUTLINED_INPUT_DEFAULT_PROPS;

export type { OutlinedInputProps };

export default OutlinedInput;
