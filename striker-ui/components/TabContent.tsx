import { ReactElement, useMemo } from 'react';

const TabContent = <T,>({
  changingTabId,
  children,
  tabId,
}: TabContentProps<T>): ReactElement => {
  const isTabIdMatch = useMemo(
    () => changingTabId === tabId,
    [changingTabId, tabId],
  );

  return <>{isTabIdMatch && children}</>;
};

export default TabContent;
