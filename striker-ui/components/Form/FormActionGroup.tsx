import ActionGroup from '../ActionGroup';

type FormActionGroupProps<V extends FormikValues> = {
  formikUtils: FormikUtils<V>;
  operation: 'add' | 'delete' | 'update';
  slotProps?: {
    group?: ActionGroupProps;
    submit?: ContainedButtonProps;
  };
};

const FormActionGroup = <V extends FormikValues>(
  ...[props]: Parameters<React.FC<FormActionGroupProps<V>>>
): ReturnType<React.FC<FormActionGroupProps<V>>> => {
  const { formikUtils, operation, slotProps } = props;

  const submit: ContainedButtonProps = {
    background: 'blue',
    disabled: formikUtils.disabledSubmit,
    type: 'submit',
    ...slotProps?.submit,
  };

  switch (operation) {
    case 'add':
      submit.children = 'Add';
      break;
    case 'delete':
      submit.background = 'red';
      submit.children = 'Delete';
      break;
    default:
      submit.children = 'Save';
  }

  return <ActionGroup actions={[submit]} {...slotProps?.group} />;
};

export type { FormActionGroupProps };

export default FormActionGroup;
