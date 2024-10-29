/** InnerPanel */

type InnerPanelOptionalProps = {
  headerMarginOffset?: number | string;
  mv?: number | string;
};

type InnerPanelProps = InnerPanelOptionalProps &
  import('@mui/material').BoxProps;

/** ExpandablePanel */

type ExpandablePanelOptionalProps = {
  expandInitially?: boolean;
  loading?: boolean;
  panelProps?: InnerPanelProps;
  showHeaderSpinner?: boolean;
};

type ExpandablePanelProps = ExpandablePanelOptionalProps & {
  header: import('react').ReactNode;
};

/** Panel */

type PanelOptionalProps = {
  paperProps?: import('@mui/material').BoxProps;
};

type PanelProps = PanelOptionalProps & import('@mui/material').PaperProps;
