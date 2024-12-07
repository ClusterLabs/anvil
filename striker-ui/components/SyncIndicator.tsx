import { Sync as SyncIcon } from '@mui/icons-material';
import { styled, SvgIconProps } from '@mui/material';

import { BLUE, UNSELECTED } from '../lib/consts/DEFAULT_THEME';

type BaseProps = {
  syncing?: boolean;
} & SvgIconProps;

const Base: React.FC<BaseProps> = ({ syncing, ...svgIconProps }) => (
  <SyncIcon {...svgIconProps} />
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
