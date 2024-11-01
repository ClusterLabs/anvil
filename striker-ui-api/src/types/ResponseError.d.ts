type ResponseErrorParams = ConstructorParameters<
  typeof import('../lib/ResponseError').ResponseError
>;

type ResponseErrorBody = {
  code: string;
  message: string;
  name: string;
};
