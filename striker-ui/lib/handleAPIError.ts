import { AxiosError, AxiosResponse } from 'axios';

import { Message } from '../components/MessageBox';

const getResonseError = <T>(data: T) => {
  const error = {
    code: '',
    message: '',
    name: '',
  };

  if (!data || typeof data !== 'object') {
    return null;
  }

  if ('code' in data) {
    error.code = String(data.code);
  }

  if ('message' in data) {
    error.message = String(data.message);
  }

  if ('name' in data) {
    error.name = String(data.name);
  }

  return error;
};

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
      const { data, status, statusText } = response;

      let msg: Message = {};

      const resError = getResonseError(data);

      if (resError) {
        msg = {
          children: `${resError.name}(${resError.code}): ${resError.message}`,
        };
      }

      if (status >= 500) {
        msg.type = 'error';

        if (!msg.children) {
          msg.children = `API responded with ${status} (${statusText})! Please check its systemd service logs.`;
        }

        return msg;
      }

      msg.type = 'warning';

      if (!msg.children) {
        msg.children = `API responded with ${status} (${statusText}).`;
      }

      return onResponseErrorAppend?.call(null, response) ?? msg;
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
