type AlertOverrideTarget = {
  description?: string;
  name: string;
  node: string;
  type: 'node' | 'subnode';
  uuid: string;
};

type AlertOverrideFormikAlertOverride = {
  level: number;
  target: AlertOverrideTarget | null;
  uuid: string;
};

type AlertOverrideFormikValues = {
  [uuid: string]: AlertOverrideFormikAlertOverride;
};

type MailRecipientFormikMailRecipient = APIMailRecipientDetail & {
  alertOverrides: AlertOverrideFormikValues;
};

type MailRecipientFormikValues = {
  [uuid: string]: MailRecipientFormikMailRecipient;
};

/** AddMailRecipientForm */

type AddMailRecipientFormOptionalProps = {
  mailRecipientUuid?: string;
  previousFormikValues?: MailRecipientFormikValues;
};

type AddMailRecipientFormProps = AddMailRecipientFormOptionalProps & {
  alertOverrideTargetOptions: AlertOverrideTarget[];
  tools: CrudListFormTools;
};

/** EditMailRecipientForm */

type EditMailRecipientFormProps = Required<AddMailRecipientFormProps>;

/** ManageAlertOverride */

type ManageAlertOverrideProps = Required<
  Pick<
    AddMailRecipientFormProps,
    'alertOverrideTargetOptions' | 'mailRecipientUuid'
  >
> & {
  formikUtils: FormikUtils<MailRecipientFormikValues>;
};

/** AlertOverrideInputGroup */

type AlertOverrideInputGroupOptionalProps = {
  alertOverrideUuid?: string;
};

type AlertOverrideInputGroupProps = AlertOverrideInputGroupOptionalProps &
  ManageAlertOverrideProps;
