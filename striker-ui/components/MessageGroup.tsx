import {
  forwardRef,
  useCallback,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import MessageBox, { Message, MessageBoxProps } from './MessageBox';

type Messages = {
  [messageKey: string]: Message | undefined;
};

type MessageGroupOptionalProps = {
  defaultMessageType?: MessageBoxProps['type'];
};

type MessageGroupProps = MessageGroupOptionalProps;

type MessageGroupForwardedRefContent = {
  setMessage?: (key: string, message?: Message) => void;
};

const MESSAGE_GROUP_DEFAULT_PROPS: Required<MessageGroupOptionalProps> = {
  defaultMessageType: 'info',
};

const MessageGroup = forwardRef<
  MessageGroupForwardedRefContent,
  MessageGroupProps
>(
  (
    { defaultMessageType = MESSAGE_GROUP_DEFAULT_PROPS.defaultMessageType },
    ref,
  ) => {
    const [messages, setMessages] = useState<Messages>({});

    const setMessage = useCallback((key: string, message?: Message) => {
      setMessages((previous) => {
        const result = { ...previous };

        result[key] = message;

        return result;
      });
    }, []);

    const messageElements = useMemo(
      () =>
        Object.entries(messages).map(([messageKey, message]) => {
          let messageElement;

          if (message) {
            const { children: messageChildren, type = defaultMessageType } =
              message;

            messageElement = (
              <MessageBox key={`message-${messageKey}`} type={type}>
                {messageChildren}
              </MessageBox>
            );
          }

          return messageElement;
        }),
      [defaultMessageType, messages],
    );

    useImperativeHandle(ref, () => ({ setMessage }), [setMessage]);

    return <>{messageElements}</>;
  },
);

MessageGroup.defaultProps = MESSAGE_GROUP_DEFAULT_PROPS;
MessageGroup.displayName = 'MessageGroup';

export type { MessageGroupForwardedRefContent };

export default MessageGroup;
