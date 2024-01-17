type MailServerFormikMailServer = {
  address: string;
  authentication: 'none' | 'plain-text' | 'encrypted';
  confirmPassword?: string;
  heloDomain: string;
  password?: string;
  port: number;
  security: 'none' | 'starttls' | 'tls-ssl';
  username?: string;
  uuid: string;
};

type MailServerFormikValues = {
  [mailServerUuid: string]: MailServerFormikMailServer;
};

/** AddMailServerForm */

type FormikSubmitHandler =
  import('formik').FormikConfig<MailServerFormikValues>['onSubmit'];

type AddMailServerFormOptionalProps = {
  localhostDomain?: string;
  mailServerUuid?: string;
  previousFormikValues?: MailServerFormikValues;
};

type AddMailServerFormProps = AddMailServerFormOptionalProps & {
  onSubmit: (
    tools: {
      mailServer: MailServerFormikMailServer;
      onConfirmCancel: FormikSubmitHandler;
      onConfirmProceed: FormikSubmitHandler;
    },
    ...args: Parameters<FormikSubmitHandler>
  ) => ReturnType<FormikSubmitHandler>;
};

/** EditMailServerForm */

type EditMailServerFormProps = Required<
  Omit<AddMailServerFormProps, 'localhostDomain'>
>;
