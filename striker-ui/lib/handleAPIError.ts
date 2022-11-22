import { AxiosError, AxiosResponse } from 'axios';

import { Message } from '../components/MessageBox';

const handleAPIError = <RequestDataType, ResponseDataType>(
  error: AxiosError<ResponseDataType, RequestDataType>,
  {
    onRequestError = (request) => ({
      children: `Incomplete request; reason: ${request}.`,
      type: 'error',
    }),
    onResponseErrorAppend,
    onSetupError = (message) => ({
      children: `Failed to setup request; reason: ${message}.`,
      type: 'error',
    }),
    // Following options rely on other values.
    onResponseError = (response) => {
      const { status, statusText } = response;

      let result: Message;

      if (status === 500) {
        result = {
          children: `The API encountered a problem: ${status} (${statusText})! Please check its systemd service logs.`,
          type: 'error',
        };
      } else {
        result = onResponseErrorAppend?.call(null, response) ?? {
          children: `API responded with ${status} (${statusText}).`,
          type: 'warning',
        };
      }
      return result;
    },
  }: {
    onRequestError?: (request: unknown) => Message;
    onResponseError?: (
      response: AxiosResponse<ResponseDataType, RequestDataType>,
    ) => Message;
    onResponseErrorAppend?: (
      response: AxiosResponse<ResponseDataType, RequestDataType>,
    ) => Message | undefined;
    onSetupError?: (message: string) => Message;
  } = {},
): Message => {
  const { request, response, message } = error;

  let result: Message;

  if (response) {
    result = onResponseError(response);
  } else if (request) {
    result = onRequestError(request);
  } else {
    result = onSetupError(message);
  }

  return result;
};

export default handleAPIError;
