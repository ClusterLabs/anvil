import MuiAutocomplete, {
  autocompleteClasses as muiAutocompleteClasses,
  AutocompleteProps as MuiAutocompleteProps,
  AutocompleteRenderInputParams as MuiAutocompleteRenderInputParams,
} from '@mui/material/Autocomplete';
import MuiBox from '@mui/material/Box';
import MuiGrow from '@mui/material/Grow';
import MuiListSubheader from '@mui/material/ListSubheader';
import muiOutlinedInputClasses from '@mui/material/OutlinedInput/outlinedInputClasses';
import MuiPaper, { PaperProps as MuiPaperProps } from '@mui/material/Paper';
import muiSvgIconClasses from '@mui/material/SvgIcon/svgIconClasses';
import styled from '@mui/material/styles/styled';
import merge from 'lodash/merge';
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
    renderInputParams?: MuiAutocompleteRenderInputParams,
  ) => void;
  getGroupLabel?: (group: string) => React.ReactNode;
  messageBoxProps?: Partial<MessageBoxProps>;
  required?: boolean;
};

type AutocompleteProps<
  T,
  Multiple extends boolean | undefined,
  DisableClearable extends boolean | undefined,
  FreeSolo extends boolean | undefined,
> = AutocompleteOptionalProps & { label: string } & Omit<
    MuiAutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
    'renderInput'
  > &
  Partial<
    Pick<
      MuiAutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
      'renderInput'
    >
  >;

const GrowPaper = (paperProps: MuiPaperProps): React.ReactElement => (
  <MuiGrow in>
    <MuiPaper {...paperProps} />
  </MuiGrow>
);

const GroupChildren = styled('ul')({
  padding: 0,
});

const GroupHeader = MuiListSubheader;

const Autocomplete = <
  T,
  Multiple extends boolean | undefined = undefined,
  DisableClearable extends boolean | undefined = undefined,
  FreeSolo extends boolean | undefined = undefined,
>(
  autocompleteProps: AutocompleteProps<T, Multiple, DisableClearable, FreeSolo>,
): React.ReactElement => {
  const {
    componentsProps,
    extendRenderInput,
    getGroupLabel,
    label,
    ListboxProps,
    messageBoxProps,
    renderGroup,
    renderInput,
    required,
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
            sx: {
              [`& .${muiOutlinedInputClasses.input}`]: {
                margin: 0,
              },
            },
          },
          label,
          required,
          value: inputProps.value,
        };

        extendRenderInput?.call(null, inputWithLabelProps, params);

        return <OutlinedInputWithLabel {...inputWithLabelProps} />;
      }),
    [extendRenderInput, label, renderInput, required],
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
    <MuiBox sx={{ display: 'flex', flexDirection: 'column' }}>
      <MuiAutocomplete
        autoHighlight
        autoSelect={required}
        PaperComponent={GrowPaper}
        {...autocompleteRestProps}
        ListboxProps={mergedListboxProps}
        renderGroup={combinedRenderGroup}
        renderInput={combinedRenderInput}
        slotProps={mergedSlotProps}
        sx={mergedSx}
      />
      <InputMessageBox {...messageBoxProps} />
    </MuiBox>
  );
};

export type { AutocompleteProps };

export default Autocomplete;
