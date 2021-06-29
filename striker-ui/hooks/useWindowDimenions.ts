import { useEffect, useState } from 'react';

const useWindowDimensions = (): number | undefined => {
  const [windowDimensions, setWindowDimensions] = useState<number | undefined>(
    undefined,
  );
  useEffect(() => {
    const handleResize = (): void => {
      setWindowDimensions(window.innerWidth);
    };
    handleResize();
    window.addEventListener('resize', handleResize);
    return (): void => window.removeEventListener('resize', handleResize);
  }, []); // Empty array ensures that effect is only run on mount

  return windowDimensions;
};

export default useWindowDimensions;
