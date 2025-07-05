import createForm from '../Form/FormFactory';
import { UpsFormikValues } from './schemas/buildUpsSchema';

type CreateOrUpdateUpsRequestBody = {
  agent: string;
  brand: string;
  ipAddress: string;
  name: string;
  typeId: string;
  uuid: string;
};

const {
  Form: UpsForm,
  FormContext: UpsFormContext,
  useFormContext: useUpsFormContext,
} = createForm<UpsFormikValues>();

export type { CreateOrUpdateUpsRequestBody };

export { UpsFormContext, useUpsFormContext };

export default UpsForm;
