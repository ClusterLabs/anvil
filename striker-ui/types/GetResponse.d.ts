declare type GetResponses<T> = {
  data: T | undefined;
  error: Error | undefined;
  isLoading: boolean;
};
