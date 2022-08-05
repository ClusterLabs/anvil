import { OutlinedInputProps as MUIOutlinedInputProps } from '@mui/material';

const INPUT_TYPES: Record<
  Exclude<MUIOutlinedInputProps['type'], undefined>,
  string
> = {
  password: 'password',
  text: 'text',
};

export default INPUT_TYPES;
