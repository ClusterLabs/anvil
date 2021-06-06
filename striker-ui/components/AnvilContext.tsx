import { createContext, useState, ReactNode } from 'react';

interface AnvilContextType {
  uuid: string;
  setAnvilUuid: (uuid: string) => void;
}

const AnvilContextDefault: AnvilContextType = {
  uuid: '',
  setAnvilUuid: () => null,
};

const AnvilContext = createContext<AnvilContextType>(AnvilContextDefault);

const AnvilProvider = ({ children }: { children: ReactNode }): JSX.Element => {
  const [uuid, setUuid] = useState<string>('');
  const setAnvilUuid = (anvilUuid: string): void => {
    setUuid(anvilUuid);
  };

  return (
    <AnvilContext.Provider value={{ uuid, setAnvilUuid }}>
      {children}
    </AnvilContext.Provider>
  );
};

export default AnvilProvider;
export { AnvilContext };
