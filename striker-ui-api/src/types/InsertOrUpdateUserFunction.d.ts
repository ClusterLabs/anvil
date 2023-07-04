type UserParams = InsertOrUpdateFunctionCommonParams & {
  user_algorithm?: string;
  user_hash_count?: number;
  user_language?: string;
  user_name: string;
  user_password_hash: string;
  user_salt?: string;
  user_uuid?: string;
};

type InsertOrUpdateUserFunction = (params: UserParams) => Promise<string>;
