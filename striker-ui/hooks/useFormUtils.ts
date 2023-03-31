import { MutableRefObject, useCallback, useMemo, useState } from 'react';

import buildMapToMessageSetter, {
  buildMessageSetter,
} from '../lib/buildMapToMessageSetter';
import buildObjectStateSetterCallback, {
  buildProtectedObjectStateSetterCallback,
} from '../lib/buildObjectStateSetterCallback';
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
  const [msgSetterList, setMsgSetterList] = useState<MapToMessageSetter<M>>(
    () => buildMapToMessageSetter<U, I, M>(ids, messageGroupRef),
  );

  const setValidity = useCallback((key: keyof M, value?: boolean) => {
    setFormValidity(
      buildObjectStateSetterCallback<FormValidity<M>>(key, value),
    );
  }, []);

  const setValidityRe = useCallback((re: RegExp, value?: boolean) => {
    setFormValidity((previous) => {
      const result: FormValidity<M> = {};

      Object.keys(previous).forEach((key) => {
        const id = key as keyof M;

        if (re.test(key)) {
          if (value !== undefined) {
            result[id] = value;
          }
        } else {
          result[id] = previous[id];
        }
      });

      return result;
    });
  }, []);

  const setMsgSetter = useCallback(
    (
      id: keyof M,
      setter?: MessageSetter,
      {
        isOverwrite,
        isUseFallback = true,
      }: { isOverwrite?: boolean; isUseFallback?: boolean } = {},
    ) => {
      const fallbackSetter: ObjectStatePropSetter<MapToMessageSetter<M>> = (
        result,
        key,
        value = buildMessageSetter<M>(String(id), messageGroupRef),
      ) => {
        result[key] = value;
      };

      setMsgSetterList(
        buildProtectedObjectStateSetterCallback<MapToMessageSetter<M>>(
          id,
          setter,
          {
            isOverwrite,
            set: isUseFallback ? fallbackSetter : undefined,
          },
        ),
      );
    },
    [messageGroupRef],
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
        setMsgSetter(key);
        setValidity(key, isValid);
      },
    [setMsgSetter, setValidity],
  );

  const isFormInvalid = useMemo(
    () => Object.values(formValidity).some((isInputValid) => !isInputValid),
    [formValidity],
  );

  return {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    formValidity,
    isFormInvalid,
    msgSetters: msgSetterList,
    setFormValidity,
    setMsgSetter,
    setValidity,
    setValidityRe,
  };
};

export default useFormUtils;
