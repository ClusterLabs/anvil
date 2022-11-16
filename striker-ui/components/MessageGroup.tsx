import {
  forwardRef,
  ReactNode,
  useCallback,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import MessageBox, { Message, MessageBoxProps } from './MessageBox';

type Messages = {
  [messageKey: string]: Message;
};

type MessageGroupOptionalProps = {
  count?: number;
  defaultMessageType?: MessageBoxProps['type'];
  onSet?: (length: number) => void;
};

type MessageGroupProps = MessageGroupOptionalProps;

type MessageGroupForwardedRefContent = {
  exists?: (key: string) => boolean;
  setMessage?: (key: string, message?: Message) => void;
  setMessageRe?: (re: RegExp, message?: Message) => void;
};

const MESSAGE_GROUP_DEFAULT_PROPS: Required<
  Omit<MessageGroupOptionalProps, 'onSet'>
> &
  Pick<MessageGroupOptionalProps, 'onSet'> = {
  count: 0,
  defaultMessageType: 'info',
  onSet: undefined,
};

const MessageGroup = forwardRef<
  MessageGroupForwardedRefContent,
  MessageGroupProps
>(
  (
    {
      count = MESSAGE_GROUP_DEFAULT_PROPS.count,
      defaultMessageType = MESSAGE_GROUP_DEFAULT_PROPS.defaultMessageType,
      onSet,
    },
    ref,
  ) => {
    const [messages, setMessages] = useState<Messages>({});

    const exists = useCallback(
      (key: string) => messages[key] !== undefined,
      [messages],
    );
    const setMessage = useCallback(
      (key: string, message?: Message) => {
        let length = 0;

        setMessages(({ [key]: unused, ...rest }) => {
          const result: Messages = rest;

          if (message) {
            result[key] = message;
          }

          length = Object.keys(result).length;

          onSet?.call(null, length);

          return result;
        });
      },
      [onSet],
    );
    const setMessageRe = useCallback(
      (re: RegExp, message?: Message) => {
        let length = 0;

        const assignMessage = message
          ? (container: Messages, key: string) => {
              container[key] = message;
              length += 1;
            }
          : undefined;

        setMessages((previous) => {
          const result: Messages = {};

          Object.keys(previous).forEach((key: string) => {
            if (re.test(key)) {
              assignMessage?.call(null, result, key);
            } else {
              result[key] = previous[key];
              length += 1;
            }
          });

          onSet?.call(null, length);

          return result;
        });
      },
      [onSet],
    );

    const messageElements = useMemo(() => {
      const pairs = Object.entries(messages);
      const isValidCount = count > 0;
      const limit = isValidCount ? count : pairs.length;
      const result: ReactNode[] = [];

      pairs.every(([messageKey, message]) => {
        const { children: messageChildren, type = defaultMessageType } =
          message;

        result.push(
          <MessageBox key={`message-${messageKey}`} type={type}>
            {messageChildren}
          </MessageBox>,
        );

        return result.length < limit;
      });

      if (isValidCount && result.length === 0) {
        result.push(
          <MessageBox
            key="message-placeholder"
            sx={{ visibility: 'hidden' }}
            text="Placeholder"
          />,
        );
      }

      return result;
    }, [count, defaultMessageType, messages]);

    useImperativeHandle(ref, () => ({ exists, setMessage, setMessageRe }), [
      exists,
      setMessage,
      setMessageRe,
    ]);

    return <>{messageElements}</>;
  },
);

MessageGroup.defaultProps = MESSAGE_GROUP_DEFAULT_PROPS;
MessageGroup.displayName = 'MessageGroup';

export type { MessageGroupForwardedRefContent };

export default MessageGroup;
