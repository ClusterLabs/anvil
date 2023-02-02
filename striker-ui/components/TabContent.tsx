import { Box } from '@mui/material';
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
  const displayValue = useMemo(
    () => (isTabIdMatch ? 'initial' : 'none'),
    [isTabIdMatch],
  );

  return <Box sx={{ display: displayValue }}>{children}</Box>;
};

export default TabContent;
