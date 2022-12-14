import { MutableRefObject } from 'react';

import { MessageGroupForwardedRefContent } from '../components/MessageGroup';

type BuildMapToMessageSetterReturnType<T extends MapToInputTestID> = {
  [MessageSetterID in keyof T]: MessageSetterFunction;
};

const buildMapToMessageSetter = <T extends MapToInputTestID>(
  mapToID: T,
  messageGroupRef: MutableRefObject<MessageGroupForwardedRefContent>,
): BuildMapToMessageSetterReturnType<T> =>
  Object.entries(mapToID).reduce<BuildMapToMessageSetterReturnType<T>>(
    (previous, [key, id]) => {
      const setter: MessageSetterFunction = (message?) => {
        messageGroupRef.current.setMessage?.call(null, id, message);
      };

      previous[key as keyof T] = setter;

      return previous;
    },
    {} as BuildMapToMessageSetterReturnType<T>,
  );

export default buildMapToMessageSetter;
