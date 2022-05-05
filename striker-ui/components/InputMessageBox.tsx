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
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...{ ...restProps, sx: { marginTop: '.4em', ...sx }, text }}
      />
    )}
  </>
);
export default InputMessageBox;
