import { FC, useMemo } from 'react';

import PrepareHostNetworkForm from './PrepareHostNetworkForm';
import Spinner from '../Spinner';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';

const PrepareHostNetwork: FC<PrepareHostNetworkProps> = (props) => {
  const { uuid } = props;

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

  const { data: detail } = useFetch<APIHostDetail>(`/host/${uuid}`);

  if (!detail) {
    return <Spinner mt={0} />;
  }

  return (
    <>
      <PrepareHostNetworkForm detail={detail} tools={formTools} uuid={uuid} />;
      {confirmDialog}
    </>
  );
};

export default PrepareHostNetwork;
