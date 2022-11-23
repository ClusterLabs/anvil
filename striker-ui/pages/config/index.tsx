import { Box, Grid } from '@mui/material';
import { FC, useEffect, useState } from 'react';

import ConfirmDialog from '../../components/ConfirmDialog';
import Header from '../../components/Header';
import {
  ComplexOperationsPanel,
  SimpleOperationsPanel,
} from '../../components/StrikerConfig';
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';
import api from '../../lib/api';

const Config: FC = () => {
  const { protect } = useProtect();

  const [isOpenConfirmDialog, setIsOpenConfirmDialog] =
    useState<boolean>(false);
  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText: '',
      content: '',
      dialogProps: { open: isOpenConfirmDialog },
      onCancelAppend: () => {
        setIsOpenConfirmDialog(false);
      },
      onProceedAppend: () => {
        setIsOpenConfirmDialog(false);
      },
      titleText: '',
    });
  const [simpleOpsPanelHeader, setSimpleOpsPanelHeader] =
    useProtectedState<string>('', protect);
  const [simpleOpsInstallTarget, setSimpleOpsInstallTarget] = useState<
    APIHostInstallTarget | undefined
  >();

  useEffect(() => {
    if (!simpleOpsPanelHeader) {
      api
        .get<APIHostDetail>('/host/local')
        .then(({ data: { installTarget, shortHostName } }) => {
          setSimpleOpsInstallTarget(installTarget);
          setSimpleOpsPanelHeader(shortHostName);
        })
        .catch(() => {
          setSimpleOpsPanelHeader('Unknown');
        });
    }
  }, [simpleOpsPanelHeader, setSimpleOpsPanelHeader]);

  return (
    <>
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
        <Header />
        <Grid container columns={{ xs: 1, md: 3, lg: 4 }}>
          <Grid item xs={1}>
            <SimpleOperationsPanel
              installTarget={simpleOpsInstallTarget}
              onSubmit={({ onProceedAppend, ...restConfirmDialogProps }) => {
                setConfirmDialogProps((previous) => ({
                  ...previous,
                  ...restConfirmDialogProps,
                  onProceedAppend: (...args) => {
                    onProceedAppend?.call(null, ...args);
                    setIsOpenConfirmDialog(false);
                  },
                }));

                setIsOpenConfirmDialog(true);
              }}
              title={simpleOpsPanelHeader}
            />
          </Grid>
          <Grid item md={2} xs={1}>
            <ComplexOperationsPanel />
          </Grid>
        </Grid>
      </Box>
      <ConfirmDialog
        {...confirmDialogProps}
        dialogProps={{ open: isOpenConfirmDialog }}
      />
    </>
  );
};

export default Config;
