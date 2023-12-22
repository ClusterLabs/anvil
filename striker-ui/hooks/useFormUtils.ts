import { MutableRefObject, useCallback, useMemo, useState } from 'react';

import api from '../lib/api';
import buildObjectStateSetterCallback, {
  buildRegExpObjectStateSetterCallback,
} from '../lib/buildObjectStateSetterCallback';
import handleAPIError from '../lib/handleAPIError';
import { Message } from '../components/MessageBox';
import { MessageGroupForwardedRefContent } from '../components/MessageGroup';
import useProtectedState from './useProtectedState';

const useFormUtils = <
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
>(
  ids: I,
  messageGroupRef: MutableRefObject<MessageGroupForwardedRefContent>,
): FormUtils<M> => {
  const [formSubmitting, setFormSubmitting] = useProtectedState<boolean>(false);
  const [formValidity, setFormValidity] = useState<FormValidity<M>>({});

  const setApiMessage = useCallback(
    (message?: Message) =>
      messageGroupRef?.current?.setMessage?.call(null, 'api', message),
    [messageGroupRef],
  );

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

  const submitForm = useCallback<SubmitFormFunction>(
    ({
      body,
      getErrorMsg,
      msgKey = 'api',
      method,
      onError,
      onSuccess,
      setMsg = messageGroupRef?.current?.setMessage,
      successMsg,
      url,
    }) => {
      setFormSubmitting(true);

      api
        .request({ data: body, method, url })
        .then(() => {
          setMsg?.call(null, msgKey, {
            children: successMsg,
            type: 'info',
          });

          onSuccess?.call(null);
        })
        .catch((apiError) => {
          const emsg = handleAPIError(apiError);

          emsg.children = getErrorMsg(emsg.children);

          setMsg?.call(null, msgKey, emsg);

          onError?.call(null);
        })
        .finally(() => {
          setFormSubmitting(false);
        });
    },
    [messageGroupRef, setFormSubmitting],
  );

  const formInvalid = useMemo(
    () => Object.values(formValidity).some((isInputValid) => !isInputValid),
    [formValidity],
  );

  return {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    buildInputUnmountFunction,
    formValidity,
    isFormInvalid: formInvalid,
    isFormSubmitting: formSubmitting,
    setApiMessage,
    setFormValidity,
    setMessage,
    setMessageRe,
    setValidity,
    setValidityRe,
    submitForm,
    unsetKey,
    unsetKeyRe,
  };
};

export default useFormUtils;
