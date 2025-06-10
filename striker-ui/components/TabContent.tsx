import { Box as MuiBox } from '@mui/material';
import { useMemo } from 'react';

const TabContent = <T,>({
  changingTabId,
  children,
  retain = false,
  tabId,
}: TabContentProps<T>): React.ReactElement => {
  const isTabIdMatch = useMemo(
    () => changingTabId === tabId,
    [changingTabId, tabId],
  );
  const result = useMemo<React.ReactNode>(
    () =>
      retain ? (
        <MuiBox sx={{ display: isTabIdMatch ? 'initial' : 'none' }}>
          {children}
        </MuiBox>
      ) : (
        isTabIdMatch && children
      ),
    [children, isTabIdMatch, retain],
  );

  return <>{result}</>;
};

export default TabContent;
