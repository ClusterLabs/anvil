type EncryptParams = SubroutineCommonParams & {
  algorithm?: string;
  hash_count?: string;
  password: string;
  salt?: string;
};

type Encrypted = {
  user_algorithm: string;
  user_hash_count: number;
  user_password_hash: string;
  user_salt: string;
};

type EncryptFunction = (params: EncryptParams) => Promise<Encrypted>;
