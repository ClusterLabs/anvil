import createForm from '../Form/FormFactory';
import { UserFormikValues } from './schemas/buildUserSchema';

const {
  Form: UserForm,
  FormContext: UserFormContext,
  useFormContext: useUserFormContext,
} = createForm<UserFormikValues>();

export { UserFormContext, useUserFormContext };

export default UserForm;
