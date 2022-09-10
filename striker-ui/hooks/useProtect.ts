import { useEffect, useRef } from 'react';

// Allow any function as callback in the protect function.
// Could be used to wrap async callbacks to prevent them from running after
// component unmount.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyFunction = (...args: any[]) => any;

type ProtectFunction = <F extends AnyFunction>(
  fn: F,
  ...args: Parameters<F>
) => ReturnType<F>;

const useProtect = (): { protect: ProtectFunction } => {
  const isComponentMountedRef = useRef<boolean>(true);

  useEffect(
    () => () => {
      isComponentMountedRef.current = false;
    },
    [],
  );

  return {
    protect: (fn, ...args) =>
      isComponentMountedRef.current ? fn(...args) : undefined,
  };
};

export default useProtect;
