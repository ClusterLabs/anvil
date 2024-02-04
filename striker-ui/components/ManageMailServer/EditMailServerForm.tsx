import { FC } from 'react';

import AddMailServerForm from './AddMailServerForm';

const EditMailServerForm: FC<EditMailServerFormProps> = (props) => (
  <AddMailServerForm {...props} />
);

export default EditMailServerForm;
