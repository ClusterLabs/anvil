import { useCallback, useMemo, useRef } from 'react';

import { DialogWithHeader } from '../Dialog';
import SyncIndicator from '../SyncIndicator';
import { HeaderText } from '../Text';
import useProvisionServerForm from './useProvisionServerForm';

const useProvisionServerDialog = () => {
  const dialogRef = useRef<DialogForwardedRefContent>(null);

  const { form, loading, validating } = useProvisionServerForm();

  const setOpen = useCallback(
    (open = false) => dialogRef.current?.setOpen(open),
    [],
  );

  const dialog = useMemo(
    () => (
      <DialogWithHeader
        header={
          <>
            <HeaderText>Provision a server</HeaderText>
            <SyncIndicator syncing={validating} />
          </>
        }
        loading={loading}
        ref={dialogRef}
        showClose
        wide
      >
        {form}
      </DialogWithHeader>
    ),
    [form, loading, validating],
  );

  return {
    dialog,
    setOpen,
  };
};

export default useProvisionServerDialog;
