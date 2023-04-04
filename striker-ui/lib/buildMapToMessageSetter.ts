import { MutableRefObject } from 'react';

import { MessageGroupForwardedRefContent } from '../components/MessageGroup';

const buildMessageSetter = <T extends MapToInputTestID>(
  id: string,
  messageGroupRef: MutableRefObject<MessageGroupForwardedRefContent>,
  container?: MapToMessageSetter<T>,
  key: string = id,
): MessageSetterFunction => {
  const setter: MessageSetterFunction = (message?) => {
    messageGroupRef.current.setMessage?.call(null, id, message);
  };

  if (container) {
    container[key as keyof T] = setter;
  }

  return setter;
};

const buildMapToMessageSetter = <
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
>(
  ids: I,
  messageGroupRef: MutableRefObject<MessageGroupForwardedRefContent>,
): MapToMessageSetter<M> => {
  let result: MapToMessageSetter<M> = {} as MapToMessageSetter<M>;

  if (ids instanceof Array) {
    result = ids.reduce<MapToMessageSetter<M>>((previous, id) => {
      buildMessageSetter(id, messageGroupRef, previous);
      return previous;
    }, result);
  } else {
    result = Object.entries(ids).reduce<MapToMessageSetter<M>>(
      (previous, [key, id]) => {
        buildMessageSetter(id, messageGroupRef, previous, key);
        return previous;
      },
      result,
    );
  }

  return result;
};

export default buildMapToMessageSetter;
