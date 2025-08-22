import MuiBox from '@mui/material/Box';
import { useState } from 'react';

import ContainedButton from './ContainedButton';
import JobProgressList from './JobProgressList';
import { BodyText } from './Text';
import useConfirmDialog from '../hooks/useConfirmDialog';
import api from '../lib/api';
import handleAPIError from '../lib/handleAPIError';

const ScanNetworkButton: React.FC = () => {
  const [jobProgress, setJobProgress] = useState<number>(0);

  const [registeredJob, setRegisteredJob] = useState<
    APIRegisteredJob | undefined
  >();

  const confirm = useConfirmDialog();

  return (
    <MuiBox>
      {registeredJob ? (
        <JobProgressList
          getLabel={(progress) =>
            progress === 100 ? 'Finished.' : 'Scanning network...'
          }
          names={['scan-network']}
          progress={{
            set: setJobProgress,
            value: jobProgress,
          }}
        />
      ) : (
        <ContainedButton
          onClick={() => {
            confirm.setConfirmDialogProps({
              actionProceedText: 'Scan',
              content: (
                <BodyText>
                  This operation will scan all networks for IP addresses,
                  including server IPs, and record them. The scan will take a
                  long time to complete; you can check the progress in the jobs
                  list.
                </BodyText>
              ),
              onProceedAppend: () => {
                confirm.setConfirmDialogLoading(true);

                api
                  .put('/command/scan-network')
                  .then((response) => {
                    if (response?.data?.uuid) {
                      setRegisteredJob(response.data);
                    }

                    confirm.finishConfirm('Success', {
                      children: <>Successfully registered network scan</>,
                    });
                  })
                  .catch((error) => {
                    const emsg = handleAPIError(error);

                    emsg.children = (
                      <>Failed to register network scan. {emsg.children}</>
                    );

                    confirm.finishConfirm('Error', emsg);
                  });
              },
              titleText: 'Start scanning networks?',
            });

            confirm.setConfirmDialogOpen(true);
          }}
        >
          Scan network
        </ContainedButton>
      )}
      {confirm.confirmDialog}
    </MuiBox>
  );
};

export default ScanNetworkButton;
