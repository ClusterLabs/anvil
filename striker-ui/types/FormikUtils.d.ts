type FormikValues = import('formik').FormikValues;

type UseFormik<Values extends FormikValues> =
  typeof import('formik').useFormik<Values>;

type Formik<Values extends FormikValues> = ReturnType<UseFormik<Values>>;

type FormikChangeHandler<Values extends FormikValues> =
  Formik<Values>['handleChange'];

type FormikSubmitHandler<Values extends FormikValues> =
  import('formik').FormikConfig<Values>['onSubmit'];
