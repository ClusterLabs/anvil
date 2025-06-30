import MuiGrid from '@mui/material/Grid2';

import AnHostInputGroup from './AnHostInputGroup';
import { ManifestFormContext, useManifestFormContext } from './ManifestForm';

const AnHostConfigInputGroup: React.FC<AnHostConfigInputGroupProps> = (
  props,
) => {
  const { knownFences, knownUpses } = props;

  const context = useManifestFormContext(ManifestFormContext);

  if (!context) {
    return null;
  }

  const { formik } = context.formikUtils;

  return (
    <MuiGrid container spacing="1em" width="100%">
      {Object.keys(formik.values.hosts).map((hostSequence) => (
        <MuiGrid key={`host-${hostSequence}`} width="100%">
          <AnHostInputGroup
            hostSequence={hostSequence}
            knownFences={knownFences}
            knownUpses={knownUpses}
          />
        </MuiGrid>
      ))}
    </MuiGrid>
  );
};

export default AnHostConfigInputGroup;
