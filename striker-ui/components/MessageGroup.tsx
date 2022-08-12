import {
  forwardRef,
  useCallback,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';
import { v4 as uuidv4 } from 'uuid';

import MessageBox, { Message, MessageBoxProps } from './MessageBox';

type MessageGroupOptionalProps = {
  defaultMessageType?: MessageBoxProps['type'];
};

type MessageGroupProps = MessageGroupOptionalProps & {
  count: number;
};

type MessageGroupForwardedRefContent = {
  setMessage?: (index: number, message?: Message) => void;
};

const MESSAGE_GROUP_DEFAULT_PROPS: Required<MessageGroupOptionalProps> = {
  defaultMessageType: 'info',
};

const MessageGroup = forwardRef<
  MessageGroupForwardedRefContent,
  MessageGroupProps
>(
  (
    {
      count,
      defaultMessageType = MESSAGE_GROUP_DEFAULT_PROPS.defaultMessageType,
    },
    ref,
  ) => {
    const { keys: messageKeys, init: initialMessages } = useMemo(
      () =>
        Array.from({ length: count }).reduce<{
          keys: string[];
          init: undefined[];
        }>(
          (previous) => {
            const { keys, init } = previous;

            keys.push(uuidv4());
            init.push(undefined);

            return previous;
          },
          { keys: [], init: [] },
        ),
      [count],
    );

    const [messages, setMessages] =
      useState<Array<Message | undefined>>(initialMessages);

    const setMessage = useCallback((index: number, message?: Message) => {
      setMessages((previous) => {
        previous.splice(index, 1, message);

        return [...previous];
      });
    }, []);

    const messageElements = useMemo(
      () =>
        messages.map((message, messageIndex) => {
          let messageElement;

          if (message) {
            const { children: messageChildren, type = defaultMessageType } =
              message;

            messageElement = (
              <MessageBox
                key={`message-${messageKeys[messageIndex]}`}
                type={type}
              >
                {messageChildren}
              </MessageBox>
            );
          }

          return messageElement;
        }),
      [defaultMessageType, messages, messageKeys],
    );

    useImperativeHandle(ref, () => ({ setMessage }), [setMessage]);

    return <>{messageElements}</>;
  },
);

MessageGroup.defaultProps = MESSAGE_GROUP_DEFAULT_PROPS;
MessageGroup.displayName = 'MessageGroup';

export type { MessageGroupForwardedRefContent };

export default MessageGroup;
