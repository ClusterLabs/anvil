import { FormikHelpers } from 'formik';

import api from '../../lib/api';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';

const handleFormSubmit = <
  Values extends FormikValues,
  Summary extends Record<string, unknown> = Record<string, unknown>,
  ReqBody = unknown,
>(
  values: Values,
  formikHelpers: FormikHelpers<Values>,
  tools: CrudListFormTools,
  buildUrl: () => string,
  buildTitle: () => React.ReactNode,
  options: {
    buildRequestBody?: (v: Values, s?: Summary) => ReqBody;
    buildSummary?: (v: Values) => Summary;
    onSuccess?: () => void;
  } = {},
) => {
  const { setSubmitting } = formikHelpers;
  const { buildRequestBody, buildSummary, onSuccess } = options;

  const summary = buildSummary?.call(null, values);

  tools.confirm.prepare({
    actionProceedText: 'Save',
    content: <FormSummary entries={summary ?? values} />,
    onCancelAppend: () => setSubmitting(false),
    onProceedAppend: () => {
      tools.confirm.loading(true);

      const body = buildRequestBody?.call(null, values, summary);

      api
        .put(buildUrl(), body ?? summary ?? values)
        .then(() => {
          tools.confirm.finish('Success', {
            children: <>Successfully registered server update job</>,
          });

          onSuccess?.call(null);

          tools.add.open(false);
          tools.edit.open(false);
        })
        .catch((error) => {
          const emsg = handleAPIError(error);

          emsg.children = (
            <>Failed to register server update job. {emsg.children}</>
          );

          tools.confirm.finish('Error', emsg);

          setSubmitting(false);
        });
    },
    titleText: buildTitle(),
  });

  tools.confirm.open(true);
};

export default handleFormSubmit;
