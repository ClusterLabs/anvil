import { useRef } from 'react';

const useIsFirstRender = (): boolean => {
  const isFirstRenderRef = useRef<boolean>(true);

  if (isFirstRenderRef.current) {
    isFirstRenderRef.current = false;

    return true;
  }

  return isFirstRenderRef.current;
};

export default useIsFirstRender;
