import * as yup from 'yup';

const protectSchema = yup.object({
  lvmVgUuid: yup.string().required('Volume group is required.'),
  protocol: yup
    .string()
    .required()
    .oneOf(['long-throw', 'short-throw', 'sync']),
});

export default protectSchema;
