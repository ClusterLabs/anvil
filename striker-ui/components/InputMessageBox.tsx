import { merge } from 'lodash';
import { useMemo } from 'react';

import MessageBox, { MessageBoxProps } from './MessageBox';

const InputMessageBox: React.FC<Partial<MessageBoxProps>> = (props) => {
  const { text } = props;

  const mergedProps = useMemo<Partial<MessageBoxProps>>(
    () =>
      merge(
        {
          sx: {
            marginTop: '.4em',
          },
        },
        props,
      ),
    [props],
  );

  if (!text) {
    return null;
  }

  return <MessageBox {...mergedProps} />;
};
export default InputMessageBox;
