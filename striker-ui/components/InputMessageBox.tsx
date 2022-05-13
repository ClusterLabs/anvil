import { FC } from 'react';

import MessageBox, { MessageBoxProps } from './MessageBox';

const InputMessageBox: FC<Partial<MessageBoxProps>> = ({
  sx,
  text,
  ...restProps
} = {}) => (
  <>
    {text && (
      <MessageBox
        {...{ ...restProps, sx: { marginTop: '.4em', ...sx }, text }}
      />
    )}
  </>
);
export default InputMessageBox;
