import {
  ExpandLess as ExpandLessIcon,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';
import { Box, IconButton } from '@mui/material';
import { FC, ReactNode, useMemo, useState } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import FlexBox from '../FlexBox';
import InnerPanel from './InnerPanel';
import InnerPanelBody from './InnerPanelBody';
import InnerPanelHeader from './InnerPanelHeader';
import Spinner from '../Spinner';

type ExpandablePanelOptionalProps = {
  isExpandInitially?: boolean;
  isLoading?: boolean;
};

type ExpandablePanelProps = ExpandablePanelOptionalProps & {
  header: ReactNode;
};

const EXPANDABLE_PANEL_DEFAULT_PROPS: Required<ExpandablePanelOptionalProps> = {
  isExpandInitially: false,
  isLoading: false,
};

const ExpandablePanel: FC<ExpandablePanelProps> = ({
  children,
  header,
  isExpandInitially = EXPANDABLE_PANEL_DEFAULT_PROPS.isExpandInitially,
  isLoading = EXPANDABLE_PANEL_DEFAULT_PROPS.isLoading,
}) => {
  const [isExpand, setIsExpand] = useState<boolean>(isExpandInitially);

  const expandButtonIcon = useMemo(
    () => (isExpand ? <ExpandLessIcon /> : <ExpandMoreIcon />),
    [isExpand],
  );
  const contentHeight = useMemo(() => (isExpand ? 'auto' : '.2em'), [isExpand]);
  const headerSpinner = useMemo(() => {
    const spinnerLength = '1.2em';

    return !isExpand && isLoading ? (
      <Spinner
        progressProps={{
          style: { height: spinnerLength, width: spinnerLength },
        }}
      />
    ) : undefined;
  }, [isExpand, isLoading]);
  const content = useMemo(
    () =>
      isExpand && isLoading ? (
        <Spinner sx={{ margin: '1em 0' }} />
      ) : (
        <InnerPanelBody>{children}</InnerPanelBody>
      ),
    [children, isExpand, isLoading],
  );

  return (
    <InnerPanel>
      <InnerPanelHeader>
        <FlexBox row>
          {header}
          {headerSpinner}
        </FlexBox>
        <IconButton
          onClick={() => {
            setIsExpand((previous) => !previous);
          }}
          sx={{ color: GREY, padding: '.2em' }}
        >
          {expandButtonIcon}
        </IconButton>
      </InnerPanelHeader>
      <Box sx={{ height: contentHeight, overflowY: 'hidden' }}>{content}</Box>
    </InnerPanel>
  );
};

ExpandablePanel.defaultProps = EXPANDABLE_PANEL_DEFAULT_PROPS;

export default ExpandablePanel;
