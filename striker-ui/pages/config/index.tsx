import { Grid } from '@mui/material';
import Head from 'next/head';
import { FC, useState } from 'react';

import ConfirmDialog from '../../components/ConfirmDialog';
import Header from '../../components/Header';
import {
  ComplexOperationsPanel,
  SimpleOperationsPanel,
} from '../../components/StrikerConfig';
import useFetch from '../../hooks/useFetch';

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

  const { data: hostDetail, loading: loadingHostDetail } =
    useFetch<APIHostDetail>(`/host/local`, {
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
