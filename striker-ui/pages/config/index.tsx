import { Grid } from '@mui/material';
import Head from 'next/head';
import { FC, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import ConfirmDialog from '../../components/ConfirmDialog';
import Header from '../../components/Header';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import {
  ComplexOperationsPanel,
  SimpleOperationsPanel,
} from '../../components/StrikerConfig';

// This page can't be reused, and default is set within the render function.
// eslint-disable-next-line react/require-default-props
const Config: FC<{ refreshInterval?: number }> = ({
  refreshInterval = 60000,
}) => {
  const [isOpenConfirmDialog, setIsOpenConfirmDialog] =
    useState<boolean>(false);
  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText: '',
      closeOnProceed: true,
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
  const [simpleOpsInstallTarget, setSimpleOpsInstallTarget] = useState<
    APIHostInstallTarget | undefined
  >();
  const [simpleOpsPanelHeader, setSimpleOpsPanelHeader] = useState<string>('');

  const { data: hostDetail, isLoading: loadingHostDetail } =
    periodicFetch<APIHostDetail>(`${API_BASE_URL}/host/local`, {
      onError: () => {
        setSimpleOpsPanelHeader('Unknown');
      },
      onSuccess: ({ installTarget, shortHostName }) => {
        setSimpleOpsInstallTarget(installTarget);
        setSimpleOpsPanelHeader(shortHostName);
      },
      refreshInterval,
    });

  return (
    <>
      <Head>
        <title>
          {loadingHostDetail
            ? 'Loading...'
            : `${hostDetail?.shortHostName} Config`}
        </title>
      </Head>
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
      <ConfirmDialog
        {...confirmDialogProps}
        dialogProps={{ open: isOpenConfirmDialog }}
      />
    </>
  );
};

export default Config;
