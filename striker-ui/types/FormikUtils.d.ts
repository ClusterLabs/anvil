type FormikValues = import('formik').FormikValues;

type ValidationSchemaDescription = import('yup').SchemaDescription;

type ValidationSchemaLazyDescription = import('yup').SchemaLazyDescription;

type ValidationSchemaRefDescription = import('yup').SchemaRefDescription;

type UseFormik<Values extends FormikValues> =
  typeof import('formik').useFormik<Values>;

type FormikConfig<Values extends FormikValues> =
  import('formik').FormikConfig<Values>;

type Formik<Values extends FormikValues> = ReturnType<UseFormik<Values>>;

type FormikChangeHandler<Values extends FormikValues> =
  Formik<Values>['handleChange'];

type FormikSubmitHandler<Values extends FormikValues> =
  FormikConfig<Values>['onSubmit'];

type FormikValidationSchemaHelpers<
  Description extends
    | ValidationSchemaDescription
    | ValidationSchemaLazyDescription
    | ValidationSchemaRefDescription =
    | ValidationSchemaDescription
    | ValidationSchemaLazyDescription
    | ValidationSchemaRefDescription,
> = {
  description: Description;
  required: (field: string) => boolean | undefined;
};

type FormikUtils<Values extends FormikValues> = {
  changeFieldValue: Formik<Values>['setFieldValue'];
  disabledSubmit: boolean;
  formik: Formik<Values>;
  formikErrors: Messages;
  getFieldChanged: (field: string) => boolean;
  getFieldIsDiff: (field: string) => boolean;
  handleChange: FormikChangeHandler<Values>;
  setFieldChanged: (field: string, value?: boolean) => void;
  validationSchemaHelpers?: FormikValidationSchemaHelpers;
};
