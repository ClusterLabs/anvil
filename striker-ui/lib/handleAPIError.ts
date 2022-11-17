import { AxiosError, AxiosResponse } from 'axios';

import { Message } from '../components/MessageBox';

const handleAPIError = <RequestDataType, ResponseDataType>(
  error: AxiosError<ResponseDataType, RequestDataType>,
  {
    onRequestError = (request) => ({
      children: `Incomplete request; reason: ${request}.`,
      type: 'error',
    }),
    onResponseError = ({ status, statusText }) => ({
      children: `API responded with ${status} (${statusText}).`,
      type: 'error',
    }),
    onSetupError = (message) => ({
      children: `Failed to setup request; reason: ${message}.`,
      type: 'error',
    }),
  }: {
    onRequestError?: (request: unknown) => Message;
    onResponseError?: (
      response: AxiosResponse<ResponseDataType, RequestDataType>,
    ) => Message;
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
