import MuiGrid, { Grid2Props as MuiGridProps } from '@mui/material/Grid2';

import AnHostConfigInputGroup from './AnHostConfigInputGroup';
import AnNetworkConfigInputGroup from './AnNetworkConfigInputGroup';
import AnIdInputGroup from './AnIdInputGroup';
import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import MessageBox from '../MessageBox';

type ManifestInputGroupProps = {
  slotProps?: {
    container?: MuiGridProps;
  };
};

const ManifestInputGroup: React.FC<ManifestInputGroupProps> = (props) => {
  const { slotProps } = props;

  const context = useManifestFormContext(ManifestFormContext);

  if (!context) {
    return <MessageBox>Missing form context.</MessageBox>;
  }

  return (
    <MuiGrid container spacing="1em" width="100%" {...slotProps?.container}>
      <MuiGrid width="100%">
        <AnIdInputGroup />
      </MuiGrid>
      <MuiGrid width="100%">
        <AnNetworkConfigInputGroup />
      </MuiGrid>
      <MuiGrid width="100%">
        <AnHostConfigInputGroup />
      </MuiGrid>
    </MuiGrid>
  );
};

export type { ManifestInputGroupProps };

export default ManifestInputGroup;
