import createForm from '../Form/FormFactory';
import { ManifestFormikValues } from './schemas/buildManifestSchema';

const {
  Form: ManifestForm,
  FormContext: ManifestFormContext,
  useFormContext: useManifestFormContext,
} = createForm<ManifestFormikValues>();

export { ManifestFormContext, useManifestFormContext };

export default ManifestForm;
