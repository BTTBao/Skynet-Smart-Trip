import {
  createContext,
  useContext,
  useMemo,
  useState,
  type PropsWithChildren,
} from 'react';

interface AdminSearchContextValue {
  query: string;
  setQuery: (value: string) => void;
  clearQuery: () => void;
}

const AdminSearchContext = createContext<AdminSearchContextValue | null>(null);

export function AdminSearchProvider({ children }: PropsWithChildren) {
  const [query, setQuery] = useState('');

  const value = useMemo(
    () => ({
      query,
      setQuery,
      clearQuery: () => setQuery(''),
    }),
    [query]
  );

  return <AdminSearchContext.Provider value={value}>{children}</AdminSearchContext.Provider>;
}

export function useAdminSearch() {
  const context = useContext(AdminSearchContext);

  if (!context) {
    throw new Error('useAdminSearch must be used within AdminSearchProvider');
  }

  return context;
}
