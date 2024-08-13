import * as yup from 'yup';

const strikerInitSchema = yup.object({
  adminPassword: yup.string().required(),
  confirmAdminPassword: yup
    .string()
    .oneOf([yup.ref('adminPassword')])
    .required(),
  domainName: yup.string().required(),
  hostName: yup.string().required(),
  hostNumber: yup.number().required(),
  organizationName: yup.string().required(),
  organizationPrefix: yup.string().min(1).max(5).required(),
});

export default strikerInitSchema;
