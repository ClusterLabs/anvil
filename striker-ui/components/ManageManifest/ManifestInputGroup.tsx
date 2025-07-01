import MuiGrid from '@mui/material/Grid2';

import AnHostConfigInputGroup from './AnHostConfigInputGroup';
import AnNetworkConfigInputGroup from './AnNetworkConfigInputGroup';
import AnIdInputGroup from './AnIdInputGroup';
import { ManifestFormContext, useManifestFormContext } from './ManifestForm';
import MessageBox from '../MessageBox';

type ManifestInputGroupProps = Pick<
  AnHostConfigInputGroupProps,
  'knownFences' | 'knownUpses'
>;

const ManifestInputGroup: React.FC<ManifestInputGroupProps> = (props) => {
  const { knownFences, knownUpses } = props;

  const context = useManifestFormContext(ManifestFormContext);

  if (!context) {
    return <MessageBox>Missing form context.</MessageBox>;
  }

  return (
    <MuiGrid container spacing="1em" width="100%">
      <MuiGrid width="100%">
        <AnIdInputGroup />
      </MuiGrid>
      <MuiGrid width="100%">
        <AnNetworkConfigInputGroup />
      </MuiGrid>
      <MuiGrid width="100%">
        <AnHostConfigInputGroup
          knownFences={knownFences}
          knownUpses={knownUpses}
        />
      </MuiGrid>
    </MuiGrid>
  );
};

export default ManifestInputGroup;
