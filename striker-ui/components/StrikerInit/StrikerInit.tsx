import { useMemo, useRef, useState } from 'react';

import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import StrikerInitForm from './StrikerInitForm';
import StrikerInitProgress from './StrikerInitProgress';
import { HeaderText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';

const StrikerInit: React.FC = () => {
  const ipRef = useRef<string>('');

  const [initJobUuid, setInitJobUuid] = useState<string | undefined>();

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog({
    initial: {
      scrollContent: true,
      wide: true,
    },
  });

  const formTools = useMemo<CrudListFormTools>(
    () => ({
      add: { open: () => null },
      confirm: {
        finish: finishConfirm,
        loading: setConfirmDialogLoading,
        open: (v = true) => setConfirmDialogOpen(v),
        prepare: setConfirmDialogProps,
      },
      edit: { open: () => null },
    }),
    [
      finishConfirm,
      setConfirmDialogLoading,
      setConfirmDialogOpen,
      setConfirmDialogProps,
    ],
  );

  const { data: detail, loading: loadingDetail } =
    useFetch<APIHostDetail>('/host/local');

  if (loadingDetail) {
    return (
      <Panel>
        <Spinner />
      </Panel>
    );
  }

  if (initJobUuid) {
    return (
      <StrikerInitProgress
        ipRef={ipRef}
        jobUuid={initJobUuid}
        reinit={Boolean(detail)}
      />
    );
  }

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>{detail ? 'Rei' : 'I'}nitialize striker</HeaderText>
        </PanelHeader>
        <StrikerInitForm
          detail={detail}
          ipRef={ipRef}
          onSubmitSuccess={(data) => {
            setInitJobUuid(data.jobUuid);
          }}
          tools={formTools}
        />
      </Panel>
      {confirmDialog}
    </>
  );
};

export default StrikerInit;
