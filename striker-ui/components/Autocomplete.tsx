import {
  Autocomplete as MUIAutocomplete,
  autocompleteClasses as muiAutocompleteClasses,
  AutocompleteProps as MUIAutocompleteProps,
  AutocompleteRenderInputParams as MUIAutocompleteRenderInputParams,
  Box,
  Grow as MUIGrow,
  ListSubheader,
  outlinedInputClasses as muiOutlinedInputClasses,
  Paper as MUIPaper,
  PaperProps as MUIPaperProps,
  svgIconClasses as muiSvgIconClasses,
  styled,
} from '@mui/material';
import { merge } from 'lodash';
import { useMemo } from 'react';

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
  getGroupLabel?: (group: string) => React.ReactNode;
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
    <MUIPaper {...paperProps} />
  </MUIGrow>
);

const GroupChildren = styled('ul')({
  padding: 0,
});

const GroupHeader = ListSubheader;

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
    getGroupLabel,
    label,
    ListboxProps,
    messageBoxProps,
    renderGroup,
    renderInput,
    sx,
    ...autocompleteRestProps
  } = autocompleteProps;

  const mergedSlotProps = useMemo<
    AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>['slotProps']
  >(
    () =>
      merge(
        {
          paper: {
            sx: {
              backgroundColor: GREY,

              [`& .${muiAutocompleteClasses.groupLabel}`]: {
                backgroundColor: GREY,
              },
            },
          },
        },
        componentsProps,
      ),
    [componentsProps],
  );

  const mergedListboxProps = useMemo<
    AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>['ListboxProps']
  >(
    () =>
      merge(
        {
          sx: {
            [`& .${muiAutocompleteClasses.option}`]: {
              [`&[aria-selected="true"]`]: {
                backgroundColor: TEXT,

                [`&.${muiAutocompleteClasses.focused}`]: {
                  backgroundColor: TEXT,
                },
              },

              [`&.${muiAutocompleteClasses.focused}`]: {
                backgroundColor: TEXT,
              },
            },
          },
        },
        ListboxProps,
      ),
    [ListboxProps],
  );

  const combinedRenderGroup = useMemo<
    AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>['renderGroup']
  >(() => {
    if (renderGroup) return renderGroup;

    return (
      getGroupLabel &&
      ((params) => (
        <li key={params.key}>
          <GroupHeader
            component="div"
            className={muiAutocompleteClasses.groupLabel}
          >
            {getGroupLabel(params.group)}
          </GroupHeader>
          <GroupChildren className={muiAutocompleteClasses.groupUl}>
            {params.children}
          </GroupChildren>
        </li>
      ))
    );
  }, [getGroupLabel, renderGroup]);

  const combinedRenderInput = useMemo<
    Exclude<
      AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>['renderInput'],
      undefined
    >
  >(
    () =>
      renderInput ??
      ((params) => {
        const { fullWidth, InputProps, InputLabelProps, inputProps } = params;
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

        extendRenderInput?.call(null, inputWithLabelProps, params);

        return <OutlinedInputWithLabel {...inputWithLabelProps} />;
      }),
    [extendRenderInput, label, renderInput],
  );

  const mergedSx = useMemo<
    AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>['sx']
  >(
    () =>
      merge(
        {
          [`& .${muiOutlinedInputClasses.root} .${muiAutocompleteClasses.endAdornment}`]:
            {
              right: `7px`,

              [`& .${muiSvgIconClasses.root}`]: {
                color: GREY,
              },
            },
        },
        sx,
      ),
    [sx],
  );

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column' }}>
      <MUIAutocomplete
        PaperComponent={GrowPaper}
        {...autocompleteRestProps}
        ListboxProps={mergedListboxProps}
        renderGroup={combinedRenderGroup}
        renderInput={combinedRenderInput}
        slotProps={mergedSlotProps}
        sx={mergedSx}
      />
      <InputMessageBox {...messageBoxProps} />
    </Box>
  );
};

export type { AutocompleteProps };

export default Autocomplete;
