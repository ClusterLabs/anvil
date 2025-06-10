import { Sync as MuiSyncIcon } from '@mui/icons-material';
import { styled, SvgIconProps as MuiSvgIconProps } from '@mui/material';

import { BLUE, UNSELECTED } from '../lib/consts/DEFAULT_THEME';

type BaseProps = {
  syncing?: boolean;
} & MuiSvgIconProps;

const Base: React.FC<BaseProps> = ({ syncing, ...svgIconProps }) => (
  <MuiSyncIcon {...svgIconProps} />
);

const SyncIndicator = styled(Base)((props) => {
  const { syncing } = props;

  let color = UNSELECTED;

  if (syncing) {
    color = BLUE;
  }

  return {
    color,
  };
});

export default SyncIndicator;
