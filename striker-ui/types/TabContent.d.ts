type TabContentOptionalProps = {
  retain?: boolean;
};

type TabContentProps<T> = TabContentOptionalProps &
  import('react').PropsWithChildren<{
    changingTabId: T;
    tabId: T;
  }>;
