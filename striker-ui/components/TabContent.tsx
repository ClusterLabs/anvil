import { Box } from '@mui/material';
import { ReactElement, ReactNode, useMemo } from 'react';

const TabContent = <T,>({
  changingTabId,
  children,
  retain = false,
  tabId,
}: TabContentProps<T>): ReactElement => {
  const isTabIdMatch = useMemo(
    () => changingTabId === tabId,
    [changingTabId, tabId],
  );
  const result = useMemo<ReactNode>(
    () =>
      retain ? (
        <Box sx={{ display: isTabIdMatch ? 'initial' : 'none' }}>
          {children}
        </Box>
      ) : (
        isTabIdMatch && children
      ),
    [children, isTabIdMatch, retain],
  );

  return <>{result}</>;
};

export default TabContent;
