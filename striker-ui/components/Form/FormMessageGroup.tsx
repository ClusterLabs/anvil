import MessageGroup, { MessageGroupProps } from '../MessageGroup';

type FormMessageGroupProps<V extends FormikValues> = {
  formikUtils: FormikUtils<V>;
  slotProps?: {
    messageGroup?: MessageGroupProps;
  };
};

const FormMessageGroup = <V extends FormikValues>(
  ...[props]: Parameters<React.FC<FormMessageGroupProps<V>>>
): ReturnType<React.FC<FormMessageGroupProps<V>>> => {
  const { formikUtils, slotProps } = props;

  return (
    <MessageGroup
      count={1}
      messages={formikUtils.formikErrors}
      {...slotProps?.messageGroup}
    />
  );
};

export type { FormMessageGroupProps };

export default FormMessageGroup;
