import { MutableRefObject, useCallback, useMemo, useState } from 'react';

import buildMapToMessageSetter, {
  buildMessageSetter,
} from '../lib/buildMapToMessageSetter';
import buildObjectStateSetterCallback from '../lib/buildObjectStateSetterCallback';
import { MessageGroupForwardedRefContent } from '../components/MessageGroup';

const useFormUtils = <
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
>(
  ids: I,
  messageGroupRef: MutableRefObject<MessageGroupForwardedRefContent>,
): FormUtils<M> => {
  const [formValidity, setFormValidity] = useState<FormValidity<M>>({});

  const setValidity = useCallback((key: keyof M, value: boolean) => {
    setFormValidity(
      buildObjectStateSetterCallback<FormValidity<M>>(key, value),
    );
  }, []);

  const buildFinishInputTestBatchFunction = useCallback(
    (key: keyof M) => (result: boolean) => {
      setValidity(key, result);
    },
    [setValidity],
  );

  const buildInputFirstRenderFunction = useCallback(
    (key: keyof M) =>
      ({ isValid }: InputFirstRenderFunctionArgs) => {
        setValidity(key, isValid);
      },
    [setValidity],
  );

  const isFormInvalid = useMemo(
    () => Object.values(formValidity).some((isInputValid) => !isInputValid),
    [formValidity],
  );

  const msgSetters = useMemo(
    () => buildMapToMessageSetter<U, I, M>(ids, messageGroupRef),
    [ids, messageGroupRef],
  );

  const setMsgSetter = useCallback(
    (id: keyof M, setter?: MessageSetterFunction, isOverwrite?: boolean) => {
      if (!msgSetters[id] || isOverwrite) {
        msgSetters[id] =
          setter ?? buildMessageSetter<M>(String(id), messageGroupRef);
      }
    },
    [messageGroupRef, msgSetters],
  );

  return {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    formValidity,
    isFormInvalid,
    msgSetters,
    setFormValidity,
    setMsgSetter,
    setValidity,
  };
};

export default useFormUtils;
