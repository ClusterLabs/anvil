type CreateUserRequestBody = {
  password?: string;
  userName: string;
};

type CreateUserResponseBody = {
  password: string;
};

type DeleteUserRequestBody = {
  uuids?: string[];
};

type UpdateUserRequestBody = Partial<CreateUserRequestBody>;

type UserParamsDictionary = {
  userUuid: string;
};
