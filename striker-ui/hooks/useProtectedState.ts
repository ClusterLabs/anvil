import { Dispatch, SetStateAction, useMemo, useState } from 'react';

import useProtect from './useProtect';

type SetStateFunction<S> = Dispatch<SetStateAction<S>>;

type SetStateParameters<S> = Parameters<SetStateFunction<S>>;

type SetStateReturnType<S> = ReturnType<SetStateFunction<S>>;

const useProtectedState = <S>(
  initialState: S | (() => S),
  protect?: (
    fn: SetStateFunction<S>,
    ...args: SetStateParameters<S>
  ) => SetStateReturnType<S>,
): [S, SetStateFunction<S>] => {
  const { protect: defaultProtect } = useProtect();

  const [state, setState] = useState<S>(initialState);

  const pfn = useMemo(
    () => protect ?? defaultProtect,
    [defaultProtect, protect],
  );

  return [
    state,
    (...args: SetStateParameters<S>): SetStateReturnType<S> =>
      pfn(setState, ...args),
  ];
};

export default useProtectedState;
