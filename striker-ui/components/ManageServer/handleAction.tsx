import { Method } from 'axios';

import api from '../../lib/api';
import handleAPIError from '../../lib/handleAPIError';

const handleAction = <ReqBody = unknown,>(
  tools: CrudListFormTools,
  url: string,
  title: React.ReactNode,
  options: {
    body?: ReqBody;
    dangerous?: boolean;
    description?: React.ReactNode;
    messages?: {
      fail?: React.ReactNode;
      proceed?: string;
      success?: React.ReactNode;
    };
    method?: Method;
    onCancel?: () => void;
    onFail?: () => void;
    onProceed?: () => void;
    onSuccess?: () => void;
  } = {},
) => {
  const {
    body,
    description,
    messages,
    method = 'put',
    onCancel,
    onFail,
    onProceed,
    onSuccess,
    dangerous = /delete/i.test(messages?.proceed ?? ''),
  } = options;

  tools.confirm.prepare({
    actionProceedText: messages?.proceed ?? 'Confirm',
    content: description,
    onCancelAppend: () => {
      onCancel?.call(null);
    },
    onProceedAppend: () => {
      tools.confirm.loading(true);

      onProceed?.call(null);

      api
        .request({
          data: body,
          method,
          url,
        })
        .then(() => {
          tools.confirm.finish('Success', {
            children: messages?.success,
          });

          onSuccess?.call(null);
        })
        .catch((error) => {
          const emsg = handleAPIError(error);

          emsg.children = (
            <>
              {messages?.fail} {emsg.children}
            </>
          );

          tools.confirm.finish('Error', emsg);

          onFail?.call(null);
        });
    },
    proceedColour: dangerous ? 'red' : undefined,
    titleText: title,
  });

  tools.confirm.open(true);
};

export default handleAction;
