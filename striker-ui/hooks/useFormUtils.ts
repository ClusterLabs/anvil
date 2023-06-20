import { MutableRefObject, useCallback, useMemo, useState } from 'react';

import buildObjectStateSetterCallback, {
  buildRegExpObjectStateSetterCallback,
} from '../lib/buildObjectStateSetterCallback';
import { Message } from '../components/MessageBox';
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

  const setMessage = useCallback(
    (key: keyof M, message?: Message) => {
      messageGroupRef?.current?.setMessage?.call(null, String(key), message);
    },
    [messageGroupRef],
  );

  const setMessageRe = useCallback(
    (re: RegExp, message?: Message) => {
      messageGroupRef?.current?.setMessageRe?.call(null, re, message);
    },
    [messageGroupRef],
  );

  const setValidity = useCallback((key: keyof M, value?: boolean) => {
    setFormValidity(
      buildObjectStateSetterCallback<FormValidity<M>>(key, value),
    );
  }, []);

  const setValidityRe = useCallback((re: RegExp, value?: boolean) => {
    setFormValidity(
      buildRegExpObjectStateSetterCallback<FormValidity<M>>(re, value),
    );
  }, []);

  const unsetKey = useCallback(
    (key: keyof M) => {
      setMessage(key);
      setValidity(key);
    },
    [setMessage, setValidity],
  );

  const unsetKeyRe = useCallback(
    (re: RegExp) => {
      setMessageRe(re);
      setValidityRe(re);
    },
    [setMessageRe, setValidityRe],
  );

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

  const buildInputUnmountFunction = useCallback(
    (key: keyof M) => () => {
      unsetKey(key);
    },
    [unsetKey],
  );

  const isFormInvalid = useMemo(
    () => Object.values(formValidity).some((isInputValid) => !isInputValid),
    [formValidity],
  );

  return {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    buildInputUnmountFunction,
    formValidity,
    isFormInvalid,
    setFormValidity,
    setMessage,
    setMessageRe,
    setValidity,
    setValidityRe,
    unsetKey,
    unsetKeyRe,
  };
};

export default useFormUtils;
