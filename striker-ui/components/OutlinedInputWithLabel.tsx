import { FC, useCallback, useMemo, useState } from 'react';
import { QuestionMark as MUIQuestionMarkIcon } from '@mui/icons-material';
import {
  FormControl as MUIFormControl,
  FormControlProps as MUIFormControlProps,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  iconButtonClasses as muiIconButtonClasses,
  InputAdornment as MUIInputAdornment,
} from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';

type OutlinedInputWithLabelOptionalProps = {
  formControlProps?: Partial<MUIFormControlProps>;
  helpMessageBoxProps?: Partial<MessageBoxProps>;
  id?: string;
  inputProps?: Partial<OutlinedInputProps>;
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
  messageBoxProps?: Partial<MessageBoxProps>;
  onChange?: OutlinedInputProps['onChange'];
  onHelp?: MUIIconButtonProps['onClick'];
  onHelpAppend?: MUIIconButtonProps['onClick'];
  value?: OutlinedInputProps['value'];
};

type OutlinedInputWithLabelProps = {
  label: string;
} & OutlinedInputWithLabelOptionalProps;

const OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS: Required<
  Omit<
    OutlinedInputWithLabelOptionalProps,
    'onChange' | 'onHelp' | 'onHelpAppend'
  >
> &
  Pick<
    OutlinedInputWithLabelOptionalProps,
    'onChange' | 'onHelp' | 'onHelpAppend'
  > = {
  formControlProps: {},
  helpMessageBoxProps: {},
  id: '',
  inputProps: {},
  inputLabelProps: {},
  messageBoxProps: {},
  onChange: undefined,
  onHelp: undefined,
  onHelpAppend: undefined,
  value: '',
};

const OutlinedInputWithLabel: FC<OutlinedInputWithLabelProps> = ({
  formControlProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.formControlProps,
  helpMessageBoxProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.helpMessageBoxProps,
  id = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.id,
  inputProps: {
    endAdornment,
    ...restInputProps
  } = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputProps,
  inputLabelProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputLabelProps,
  label,
  messageBoxProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.messageBoxProps,
  onChange,
  onHelp,
  onHelpAppend,
  value = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.value,
}) => {
  const { text: helpText = '' } = helpMessageBoxProps;

  const [isShowHelp, setIsShowHelp] = useState<boolean>(false);

  const isShowHelpButton: boolean = useMemo(
    () => onHelp !== undefined || helpText.length > 0,
    [helpText, onHelp],
  );

  const createHelpHandler = useCallback<
    () => MUIIconButtonProps['onClick']
  >(() => {
    let handler: MUIIconButtonProps['onClick'];

    if (onHelp) {
      handler = onHelp;
    } else if (helpText.length > 0) {
      handler = (...args) => {
        setIsShowHelp((previous) => !previous);
        onHelpAppend?.call(null, ...args);
      };
    }

    return handler;
  }, [helpText, onHelp, onHelpAppend]);
  const handleHelp = useMemo(createHelpHandler, [createHelpHandler]);

  return (
    <MUIFormControl {...formControlProps}>
      <OutlinedInputLabel {...{ htmlFor: id, ...inputLabelProps }}>
        {label}
      </OutlinedInputLabel>
      <OutlinedInput
        {...{
          endAdornment: (
            <MUIInputAdornment
              position="end"
              sx={{
                display: 'flex',
                flexDirection: 'row',

                [`& > .${muiIconButtonClasses.root}`]: {
                  color: GREY,
                },

                [`& > :not(:first-child, .${muiIconButtonClasses.root})`]: {
                  marginLeft: '.3em',
                },
              }}
            >
              {endAdornment}
              {isShowHelpButton && (
                <MUIIconButton onClick={handleHelp} tabIndex={-1}>
                  <MUIQuestionMarkIcon />
                </MUIIconButton>
              )}
            </MUIInputAdornment>
          ),
          fullWidth: formControlProps.fullWidth,
          id,
          label,
          onChange,
          value,
          ...restInputProps,
        }}
      />
      {isShowHelp && (
        <InputMessageBox
          {...{
            onClose: () => {
              setIsShowHelp(false);
            },

            ...helpMessageBoxProps,
          }}
        />
      )}
      <InputMessageBox {...messageBoxProps} />
    </MUIFormControl>
  );
};

OutlinedInputWithLabel.defaultProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS;

export type { OutlinedInputWithLabelProps };

export default OutlinedInputWithLabel;
