import {
  Dispatch,
  MutableRefObject,
  SetStateAction,
  useCallback,
  useMemo,
  useState,
} from 'react';

import buildMapToMessageSetter from '../lib/buildMapToMessageSetter';
import buildObjectStateSetterCallback from '../lib/buildObjectStateSetterCallback';
import { MessageGroupForwardedRefContent } from '../components/MessageGroup';

type FormValidity<T> = {
  [K in keyof T]?: boolean;
};

const useFormUtils = <
  U extends string,
  I extends InputIds<U>,
  M extends MapToInputId<U, I>,
>(
  ids: I,
  messageGroupRef: MutableRefObject<MessageGroupForwardedRefContent>,
): {
  buildFinishInputTestBatchFunction: (
    key: keyof M,
  ) => (result: boolean) => void;
  buildInputFirstRenderFunction: (
    key: keyof M,
  ) => ({ isRequired }: { isRequired: boolean }) => void;
  formValidity: FormValidity<M>;
  isFormInvalid: boolean;
  msgSetters: MapToMessageSetter<M>;
  setFormValidity: Dispatch<SetStateAction<FormValidity<M>>>;
} => {
  const [formValidity, setFormValidity] = useState<FormValidity<M>>({});

  const buildFinishInputTestBatchFunction = useCallback(
    (key: keyof M) => (result: boolean) => {
      setFormValidity(
        buildObjectStateSetterCallback<FormValidity<M>>(key, result),
      );
    },
    [],
  );

  const buildInputFirstRenderFunction = useCallback(
    (key: keyof M) =>
      ({ isRequired }: { isRequired: boolean }) => {
        setFormValidity(
          buildObjectStateSetterCallback<FormValidity<M>>(key, !isRequired),
        );
      },
    [],
  );

  const isFormInvalid = useMemo(
    () => Object.values(formValidity).some((isInputValid) => !isInputValid),
    [formValidity],
  );

  const msgSetters = useMemo(
    () => buildMapToMessageSetter<U, I, M>(ids, messageGroupRef),
    [ids, messageGroupRef],
  );

  return {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    formValidity,
    isFormInvalid,
    msgSetters,
    setFormValidity,
  };
};

export default useFormUtils;
