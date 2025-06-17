import MuiExpandLessIcon from '@mui/icons-material/ExpandLess';
import MuiExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { Box as MuiBox, IconButton as MuiIconButton } from '@mui/material';
import { useMemo, useState } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import FlexBox from '../FlexBox';
import InnerPanel from './InnerPanel';
import InnerPanelBody from './InnerPanelBody';
import InnerPanelHeader from './InnerPanelHeader';
import Spinner from '../Spinner';
import { BodyText } from '../Text';

const HEADER_SPINNER_LENGTH = '1.2em';

const ExpandablePanel: React.FC<
  React.PropsWithChildren<ExpandablePanelProps>
> = ({
  children,
  expandInitially: isExpandInitially = false,
  header,
  loading: isLoading = false,
  panelProps,
  showHeaderSpinner: isShowHeaderSpinner = false,
}) => {
  const [isExpand, setIsExpand] = useState<boolean>(isExpandInitially);

  const expandButtonIcon = useMemo(
    () => (isExpand ? <MuiExpandLessIcon /> : <MuiExpandMoreIcon />),
    [isExpand],
  );
  const contentHeight = useMemo(() => (isExpand ? 'auto' : '.2em'), [isExpand]);
  const headerElement = useMemo(
    () => (typeof header === 'string' ? <BodyText>{header}</BodyText> : header),
    [header],
  );
  const headerSpinner = useMemo(
    () =>
      isShowHeaderSpinner && !isExpand && isLoading ? (
        <Spinner
          progressProps={{
            style: {
              height: HEADER_SPINNER_LENGTH,
              width: HEADER_SPINNER_LENGTH,
            },
          }}
        />
      ) : undefined,
    [isExpand, isLoading, isShowHeaderSpinner],
  );
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
    <InnerPanel {...panelProps}>
      <InnerPanelHeader>
        <FlexBox row>
          {headerElement}
          {headerSpinner}
        </FlexBox>
        <MuiIconButton
          onClick={() => {
            setIsExpand((previous) => !previous);
          }}
          sx={{ color: GREY, padding: '.2em' }}
        >
          {expandButtonIcon}
        </MuiIconButton>
      </InnerPanelHeader>
      <MuiBox sx={{ height: contentHeight, overflowY: 'hidden' }}>
        {content}
      </MuiBox>
    </InnerPanel>
  );
};

export default ExpandablePanel;
