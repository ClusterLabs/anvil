import { FC } from 'react';
import { Box } from '@mui/material';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import SelectWithLabel, {
  SelectItem,
  SelectWithLabelProps,
} from './SelectWithLabel';

type OutlinedLabeledInputWithSelectOptionalProps = {
  inputWithLabelProps?: Partial<OutlinedInputWithLabelProps>;
  messageBoxProps?: Partial<MessageBoxProps>;
  selectWithLabelProps?: Partial<SelectWithLabelProps>;
};

type OutlinedLabeledInputWithSelectProps =
  OutlinedLabeledInputWithSelectOptionalProps & {
    id: string;
    label: string;
    selectItems: SelectItem[];
  };

const OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS: Required<OutlinedLabeledInputWithSelectOptionalProps> =
  {
    inputWithLabelProps: {},
    messageBoxProps: {},
    selectWithLabelProps: {},
  };

const OutlinedLabeledInputWithSelect: FC<
  OutlinedLabeledInputWithSelectProps
> = ({
  id,
  label,
  inputWithLabelProps,
  messageBoxProps,
  selectItems,
  selectWithLabelProps,
}) => (
  <Box>
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'row',

        '& > :first-child': {
          flexGrow: 1,
        },

        '& > :not(:last-child)': {
          marginRight: '.5em',
        },
      }}
    >
      <OutlinedInputWithLabel
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...{
          id,
          label,
          ...inputWithLabelProps,
        }}
      />
      <SelectWithLabel
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...{
          id: `${id}-nested-select`,
          selectItems,
          ...selectWithLabelProps,
        }}
      />
    </Box>
    {/* eslint-disable-next-line react/jsx-props-no-spreading */}
    <InputMessageBox {...messageBoxProps} />
  </Box>
);

OutlinedLabeledInputWithSelect.defaultProps =
  OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS;

export type { OutlinedLabeledInputWithSelectProps };

export default OutlinedLabeledInputWithSelect;
