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

type AddMailServerFormOptionalProps = {
  localhostDomain?: string;
  mailServerUuid?: string;
  previousFormikValues?: MailServerFormikValues;
};

type AddMailServerFormProps = AddMailServerFormOptionalProps & {
  tools: CrudListFormTools;
};

/** EditMailServerForm */

type EditMailServerFormProps = Required<
  Omit<AddMailServerFormProps, 'localhostDomain'>
>;
