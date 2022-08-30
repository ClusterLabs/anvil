import {
  ExpandLess as ExpandLessIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';
import { Box, IconButton } from '@mui/material';
import { FC, ReactNode, useMemo, useState } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import InnerPanel from './InnerPanel';
import InnerPanelBody from './InnerPanelBody';
import InnerPanelHeader from './InnerPanelHeader';

type ExpandablePanelOptionalProps = {
  isExpandInitially?: boolean;
};

type ExpandablePanelProps = ExpandablePanelOptionalProps & {
  header: ReactNode;
};

const EXPANDABLE_PANEL_DEFAULT_PROPS: Required<ExpandablePanelOptionalProps> = {
  isExpandInitially: false,
};

const ExpandablePanel: FC<ExpandablePanelProps> = ({
  children,
  header,
  isExpandInitially = EXPANDABLE_PANEL_DEFAULT_PROPS.isExpandInitially,
}) => {
  const [isExpand, setIsExpand] = useState<boolean>(isExpandInitially);

  const expandButtonIcon = useMemo(
    () => (isExpand ? <ExpandLessIcon /> : <ExpandMoreIcon />),
    [isExpand],
  );
  const contentHeight = useMemo(() => (isExpand ? 'auto' : '.2em'), [isExpand]);

  return (
    <InnerPanel>
      <InnerPanelHeader>
        {header}
        <IconButton
          onClick={() => {
            setIsExpand((previous) => !previous);
          }}
          sx={{ color: GREY, padding: '.2em' }}
        >
          {expandButtonIcon}
        </IconButton>
      </InnerPanelHeader>
      <Box sx={{ height: contentHeight, overflowY: 'hidden' }}>
        <InnerPanelBody>{children}</InnerPanelBody>
      </Box>
    </InnerPanel>
  );
};

ExpandablePanel.defaultProps = EXPANDABLE_PANEL_DEFAULT_PROPS;

export default ExpandablePanel;
