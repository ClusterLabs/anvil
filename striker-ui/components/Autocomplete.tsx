import {
  Autocomplete as MUIAutocomplete,
  autocompleteClasses as muiAutocompleteClasses,
  AutocompleteProps as MUIAutocompleteProps,
  AutocompleteRenderInputParams as MUIAutocompleteRenderInputParams,
  Box,
  Grow as MUIGrow,
  outlinedInputClasses as muiOutlinedInputClasses,
  Paper as MUIPaper,
  PaperProps as MUIPaperProps,
  svgIconClasses as muiSvgIconClasses,
} from '@mui/material';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';

type AutocompleteOptionalProps = {
  extendRenderInput?: (
    inputWithLabelProps: OutlinedInputWithLabelProps,
    renderInputParams?: MUIAutocompleteRenderInputParams,
  ) => void;
  messageBoxProps?: Partial<MessageBoxProps>;
};

type AutocompleteProps<
  T,
  Multiple extends boolean | undefined,
  DisableClearable extends boolean | undefined,
  FreeSolo extends boolean | undefined,
> = AutocompleteOptionalProps & { label: string } & Omit<
    MUIAutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
    'renderInput'
  > &
  Partial<
    Pick<
      MUIAutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
      'renderInput'
    >
  >;

const GrowPaper = (paperProps: MUIPaperProps): JSX.Element => (
  <MUIGrow in>
    {/* eslint-disable-next-line react/jsx-props-no-spreading */}
    <MUIPaper {...paperProps} />
  </MUIGrow>
);

const Autocomplete = <
  T,
  Multiple extends boolean | undefined = undefined,
  DisableClearable extends boolean | undefined = undefined,
  FreeSolo extends boolean | undefined = undefined,
>(
  autocompleteProps: AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
): JSX.Element => {
  const {
    componentsProps,
    extendRenderInput,
    label,
    messageBoxProps,
    renderInput,
    sx,
  } = autocompleteProps;
  const combinedComponentsProps: AutocompleteProps<
    T,
    Multiple,
    DisableClearable,
    FreeSolo
  >['componentsProps'] = {
    paper: {
      sx: {
        backgroundColor: TEXT,
      },
    },

    ...componentsProps,
  };
  const combinedRenderInput =
    renderInput ??
    ((renderInputParams) => {
      const { fullWidth, InputProps, InputLabelProps, inputProps } =
        renderInputParams;
      const inputWithLabelProps: OutlinedInputWithLabelProps = {
        formControlProps: {
          fullWidth,
          ref: InputProps.ref,
        },
        inputLabelProps: InputLabelProps,
        inputProps: {
          className: InputProps.className,
          endAdornment: InputProps.endAdornment,
          inputProps,
          startAdornment: InputProps.startAdornment,
        },
        label,
      };

      extendRenderInput?.call(null, inputWithLabelProps, renderInputParams);

      // eslint-disable-next-line react/jsx-props-no-spreading
      return <OutlinedInputWithLabel {...inputWithLabelProps} />;
    });
  const combinedSx = {
    [`& .${muiOutlinedInputClasses.root} .${muiAutocompleteClasses.endAdornment}`]:
      {
        right: `7px`,

        [`& .${muiSvgIconClasses.root}`]: {
          color: GREY,
        },
      },

    ...sx,
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column' }}>
      <MUIAutocomplete
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...{
          PaperComponent: GrowPaper,
          ...autocompleteProps,
          componentsProps: combinedComponentsProps,
          renderInput: combinedRenderInput,
          sx: combinedSx,
        }}
      />
      {/* eslint-disable-next-line react/jsx-props-no-spreading */}
      <InputMessageBox {...messageBoxProps} />
    </Box>
  );
};

export type { AutocompleteProps };

export default Autocomplete;
