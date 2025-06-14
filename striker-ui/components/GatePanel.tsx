import { useRouter } from 'next/router';

import api from '../lib/api';
import GateForm from './GateForm';
import handleAPIError from '../lib/handleAPIError';
import { Panel } from './Panels';

const GatePanel: React.FC = () => {
  const {
    query: { rt: returnTo },
  } = useRouter();

  return (
    <Panel
      sx={{
        marginLeft: { xs: '1em', sm: 'auto' },
        marginRight: { xs: '1em', sm: 'auto' },
        marginTop: 'calc(50vh - 14em)',
        minWidth: '16em',
        width: { xs: 'fit-content', sm: '26em' },
      }}
    >
      <GateForm
        gridProps={{ columns: 1 }}
        identifierLabel="Username"
        onSubmitAppend={(username, password, setMessage, setIsSubmitting) => {
          setIsSubmitting(true);

          api
            .post('/auth/login', { username, password })
            .then(() => {
              const url = returnTo ? String(returnTo) : '/';

              window.location.replace(url);
            })
            .catch((error) => {
              const emsg = handleAPIError(error, {
                onResponseErrorAppend: () => ({
                  children: `Credentials mismatched.`,
                  type: 'warning',
                }),
              });

              setMessage(emsg);
            })
            .finally(() => {
              setIsSubmitting(false);
            });
        }}
        passphraseLabel="Passphrase"
        submitLabel="Login"
      />
    </Panel>
  );
};

export default GatePanel;
