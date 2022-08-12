import {
  forwardRef,
  useCallback,
  useEffect,
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
    const [messageKeys, setMessageKeys] = useState<string[]>([]);
    const [messages, setMessages] = useState<Array<Message | undefined>>([]);

    const setMessage = useCallback((index: number, message?: Message) => {
      setMessages((previous) => {
        const result = [...previous];
        const diff = index + 1 - result.length;

        if (diff > 0) {
          result.push(...Array.from({ length: diff }, () => undefined));
        }

        result.splice(index, 1, message);

        return result;
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

    useEffect(() => {
      setMessageKeys((previous) => {
        const result = [...previous];
        const diff = count - result.length;

        if (diff > 0) {
          result.push(...Array.from({ length: diff }, () => uuidv4()));
        }

        return result;
      });
    }, [count]);

    useImperativeHandle(ref, () => ({ setMessage }), [setMessage]);

    return <>{messageElements}</>;
  },
);

MessageGroup.defaultProps = MESSAGE_GROUP_DEFAULT_PROPS;
MessageGroup.displayName = 'MessageGroup';

export type { MessageGroupForwardedRefContent };

export default MessageGroup;
