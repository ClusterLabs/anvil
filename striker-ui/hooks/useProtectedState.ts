import { Dispatch, SetStateAction, useState } from 'react';

type SetStateFunction<S> = Dispatch<SetStateAction<S>>;

type SetStateParameters<S> = Parameters<SetStateFunction<S>>;

type SetStateReturnType<S> = ReturnType<SetStateFunction<S>>;

const useProtectedState = <S>(
  initialState: S | (() => S),
  protect: (
    fn: SetStateFunction<S>,
    ...args: SetStateParameters<S>
  ) => SetStateReturnType<S>,
): [S, SetStateFunction<S>] => {
  const [state, setState] = useState<S>(initialState);

  return [
    state,
    (...args: SetStateParameters<S>): SetStateReturnType<S> =>
      protect(setState, ...args),
  ];
};

export default useProtectedState;
