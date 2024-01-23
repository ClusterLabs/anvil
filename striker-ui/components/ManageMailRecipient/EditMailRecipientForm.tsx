import { FC } from 'react';

import AddMailRecipientForm from './AddMailRecipientForm';

const EditMailRecipientForm: FC<EditMailRecipientFormProps> = (props) => (
  <AddMailRecipientForm {...props} />
);

export default EditMailRecipientForm;
