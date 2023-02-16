type ExpandablePanelOptionalProps = {
  expandInitially?: boolean;
  loading?: boolean;
  panelProps?: InnerPanelProps;
  showHeaderSpinner?: boolean;
};

type ExpandablePanelProps = ExpandablePanelOptionalProps & {
  header: import('react').ReactNode;
};
