import { createContext } from 'react';

type ManifestInputContextValue = {
  hosts: APIHostDetailList;
  template: APIManifestTemplate;
};

const ManifestInputContext = createContext<ManifestInputContextValue | null>(
  null,
);

export type { ManifestInputContextValue };

export default ManifestInputContext;
