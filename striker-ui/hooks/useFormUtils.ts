import { useCallback, useMemo, useReducer, useState } from 'react';

import api from '../lib/api';
import buildObjectStateSetterCallback, {
  buildRegExpObjectStateSetterCallback,
} from '../lib/buildObjectStateSetterCallback';
import handleAPIError from '../lib/handleAPIError';
import { Message } from '../components/MessageBox';
import { MessageGroupForwardedRefContent } from '../components/MessageGroup';

type FormValidityAction<
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
> = {
  key?: keyof M;
  re?: RegExp;
  replace?: FormValidity<M>;
  value?: boolean;
};

const formValidityReducer = <
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
>(
  previous: FormValidity<M>,
  action: FormValidityAction<U, I, M>,
): FormValidity<M> => {
  const { key, re, replace, value } = action;

  if (key) {
    if (previous[key] === value) {
      return previous;
    }

    return buildObjectStateSetterCallback<FormValidity<M>>(
      key,
      value,
    )(previous);
  }

  if (re) {
    return buildRegExpObjectStateSetterCallback<FormValidity<M>>(
      re,
      value,
    )(previous);
  }

  if (replace) {
    return replace;
  }

  return previous;
};

const useFormUtils = <
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
>(
  ids: I,
  messageGroupRef?: React.RefObject<MessageGroupForwardedRefContent>,
): FormUtils<M> => {
  const [formSubmitting, setFormSubmitting] = useState<boolean>(false);

  const [formValidity, dispatchFormValidity] = useReducer<
    FormValidity<M>,
    [FormValidityAction<U, I, M>]
  >(formValidityReducer, {});

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

  const setFormValidity = useCallback((value: FormValidity<M>) => {
    dispatchFormValidity({
      replace: value,
    });
  }, []);

  const setValidity = useCallback((key: keyof M, value?: boolean) => {
    dispatchFormValidity({
      key,
      value,
    });
  }, []);

  const setValidityRe = useCallback((re: RegExp, value?: boolean) => {
    dispatchFormValidity({
      re,
      value,
    });
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
    (key: keyof M) => (value: boolean) => {
      setValidity(key, value);
    },
    [setValidity],
  );

  const buildInputFirstRenderFunction = useCallback(
    (key: keyof M) =>
      ({ isValid: value }: InputFirstRenderFunctionArgs) => {
        setValidity(key, value);
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
        .catch((error) => {
          const emsg = handleAPIError(error);

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
