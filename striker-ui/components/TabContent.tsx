import MuiBox from '@mui/material/Box';
import { useMemo } from 'react';

const TabContent = <T,>(
  ...[props]: Parameters<React.FC<TabContentProps<T>>>
): ReturnType<React.FC<TabContentProps<T>>> => {
  const { changingTabId, children, retain = false, tabId } = props;

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
