type AlertOverrideRequest = {
  body?: {
    hostUuid: string;
    level: number;
    mailRecipientUuid: string;
  };
  method: 'delete' | 'post' | 'put';
  url: string;
};

type AlertOverrideTarget = {
  description?: string;
  name: string;
  node: string;
  subnodes?: string[];
  type: 'node' | 'subnode';
  uuid: string;
};

type AlertOverrideFormikAlertOverride = {
  level: number;
  remove?: boolean;
  target: AlertOverrideTarget | null;
  uuids?: Record<string, string>;
};

type AlertOverrideFormikValues = {
  [valueId: string]: AlertOverrideFormikAlertOverride;
};

type MailRecipientFormikMailRecipient = Omit<APIMailRecipientDetail, 'uuid'> & {
  alertOverrides: AlertOverrideFormikValues;
  uuid?: string;
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
  alertOverrideValueId?: string;
};

type AlertOverrideInputGroupProps = AlertOverrideInputGroupOptionalProps &
  ManageAlertOverrideProps;
