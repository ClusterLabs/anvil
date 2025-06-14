import { createContext, useMemo, useState } from 'react';

interface AnvilContextValue {
  setAnvilUuid?: (uuid: string) => void;
  uuid: string;
}

const AnvilContext = createContext<AnvilContextValue>({
  uuid: '',
});

const AnvilProvider: React.FC<React.PropsWithChildren> = (props) => {
  const { children } = props;

  const [uuid, setUuid] = useState<string>('');

  const contextValue = useMemo<AnvilContextValue>(
    () => ({
      uuid,
      setAnvilUuid: (id) => {
        if (id === uuid) {
          return;
        }

        setUuid(id);
      },
    }),
    [uuid],
  );

  return (
    <AnvilContext.Provider value={contextValue}>
      {children}
    </AnvilContext.Provider>
  );
};

export { AnvilContext };

export default AnvilProvider;
