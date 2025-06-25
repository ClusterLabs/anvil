import MuiGrid from '@mui/material/Grid2';
import { useMemo, useRef, useState } from 'react';

import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import { DialogWithHeader } from '../Dialog';
import FlexBox from '../FlexBox';
import handleFormSubmit from '../Form/handleFormSubmit';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import { ExpandablePanel } from '../Panels';
import PeerStrikerForm, {
  CreatePeerStrikerRequestBody,
} from './PeerStrikerForm';
import PeerStrikerInputGroup from './PeerStrikerInputGroup';
import State from '../State';
import { BodyText, MonoText, SmallText } from '../Text';
import getPeerStrikerFormikInitialValues from './getPeerStrikerFormikInitialValues';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';
import api from '../../lib/api';
import handleAPIError from '../../lib/handleAPIError';
import buildPeerStrikerSchema from './schemas/buildPeerStrikerSchema';

import {
  INPUT_ID_PEER_STRIKER_PASSWORD,
  INPUT_ID_PEER_STRIKER_PING_TEST,
  INPUT_ID_PEER_STRIKER_TARGET,
} from './inputIds';

type ManagePeerStrikerProps = {
  refreshInterval?: number;
};

const ManagePeerStriker: React.FC<ManagePeerStrikerProps> = ({
  refreshInterval = 60000,
}) => {
  const addDialogRef = useRef<DialogForwardedRefContent>(null);

  const confirm = useConfirmDialog();

  const [apiMessage, setApiMessage] = useState<Message | undefined>();

  const [editPeerConnections, setEditPeerConnections] =
    useState<boolean>(false);

  const apiMessageElement = useMemo(
    () =>
      apiMessage && (
        <MuiGrid
          size={{
            xs: 1,
            sm: 2,
          }}
        >
          <MessageBox {...apiMessage} />
        </MuiGrid>
      ),
    [apiMessage],
  );

  const {
    data: connections,
    loading: loadingConnections,
    mutate: getConnections,
  } = useFetch<APIHostConnectionOverviewList>(`/host/connection`, {
    onError: (error) => {
      const emsg = handleAPIError(error);

      emsg.children = <>Failed to get connection data. {emsg.children}</>;

      setApiMessage(emsg);
    },
    onSuccess: () => {
      setApiMessage(undefined);
    },
    refreshInterval,
  });

  const inboundConnections = useMemo<InboundConnectionList | undefined>(() => {
    if (!connections) {
      return undefined;
    }

    const {
      ipAddress: ls,
      port: dbPort,
      user: dbUser,
    } = connections.local.inbound;

    return Object.entries(ls).reduce<InboundConnectionList>(
      (previous, entry) => {
        const [
          ipAddress,
          { ifaceId, networkLinkNumber, networkNumber, networkType },
        ] = entry;

        previous[ipAddress] = {
          dbPort,
          dbUser,
          ifaceId,
          ipAddress,
          networkLinkNumber,
          networkNumber,
          networkType,
        };

        return previous;
      },
      {},
    );
  }, [connections]);

  const peerConnections = useMemo<PeerConnectionList | undefined>(() => {
    if (!connections) {
      return undefined;
    }

    const { peer: ls } = connections.local;

    return Object.entries(ls).reduce<PeerConnectionList>((previous, entry) => {
      const [
        peerIpAddress,
        {
          hostUUID: hostUuid,
          isPing: isPingTest,
          port: peerDbPort,
          user: peerDbUser,
        },
      ] = entry;

      const peerKey = `${peerDbUser}@${peerIpAddress}:${peerDbPort}`;

      previous[peerKey] = {
        dbPort: peerDbPort,
        dbUser: peerDbUser,
        hostUUID: hostUuid,
        ipAddress: peerIpAddress,
        isPingTest,
      };

      return previous;
    }, {});
  }, [connections]);

  const { checks, getCheck, hasChecks, resetChecks, setCheck } = useChecklist({
    list: peerConnections,
  });

  return (
    <>
      <ExpandablePanel
        header="Configure striker peers"
        loading={loadingConnections}
      >
        <MuiGrid
          columns={{
            xs: 1,
            sm: 2,
          }}
          container
          spacing="1em"
          width="100%"
        >
          <MuiGrid size={1}>
            <List
              header="Inbound connections"
              listEmpty={
                <BodyText align="center">
                  No inbound connections found.
                </BodyText>
              }
              listItemKeyPrefix="inbound"
              listItems={inboundConnections}
              loading={loadingConnections}
              renderListItem={(
                ipAddress,
                { dbPort, dbUser, ifaceId, networkNumber, networkType },
              ) => {
                const network: string =
                  NETWORK_TYPES[networkType] && networkNumber
                    ? `${NETWORK_TYPES[networkType]} ${networkNumber}`
                    : `Unknown network; interface: ${ifaceId}`;

                return (
                  <FlexBox spacing={0} sx={{ width: '100%' }}>
                    <MonoText>{`${dbUser}@${ipAddress}:${dbPort}`}</MonoText>
                    <SmallText>{network}</SmallText>
                  </FlexBox>
                );
              }}
            />
          </MuiGrid>
          <MuiGrid size={1}>
            <List
              allowEdit
              disableDelete={!hasChecks}
              edit={editPeerConnections}
              header="Peer connections"
              listEmpty={
                <BodyText align="center">No peer connections found.</BodyText>
              }
              listItemKeyPrefix="peer"
              listItems={peerConnections}
              loading={loadingConnections}
              onAdd={() => {
                addDialogRef.current?.setOpen(true);
              }}
              onDelete={() => {
                if (!peerConnections) {
                  return;
                }

                const deleteRequestBody: APIDeleteHostConnectionRequestBody = {
                  local: checks.map<string>((key) => {
                    const { [key]: connection } = peerConnections;

                    return connection.hostUUID;
                  }),
                };

                const deleteCount = deleteRequestBody.local.length;

                if (deleteCount > 0) {
                  confirm.setConfirmDialogProps({
                    actionProceedText: 'Delete',
                    content: `The peer relationship between this striker and the selected ${deleteCount} host(s) will terminate. The removed peer(s) can be re-added later.`,
                    onProceedAppend: () => {
                      api
                        .delete('/host/connection', {
                          data: deleteRequestBody,
                        })
                        .then(() => {
                          resetChecks();

                          getConnections();

                          confirm.setConfirmDialogOpen(false);
                        })
                        .catch((error) => {
                          const emsg = handleAPIError(error);

                          confirm.finishConfirm('Error', {
                            children: `Failed to delete peer connection(s). ${emsg.children}`,
                          });
                        });
                    },
                    proceedColour: 'red',
                    titleText: `Delete ${deleteCount} peer(s) from this striker?`,
                  });

                  confirm.setConfirmDialogOpen(true);
                }
              }}
              onEdit={() => {
                setEditPeerConnections((previous) => !previous);
              }}
              onItemCheckboxChange={(key, event, checked) => {
                setCheck(key, checked);
              }}
              renderListItemCheckboxState={(key) => getCheck(key)}
              renderListItem={(peer, { isPingTest = false }) => (
                <FlexBox row spacing={0}>
                  <FlexBox spacing={0}>
                    <MonoText>{peer}</MonoText>
                    <State label="Ping" state={isPingTest} />
                  </FlexBox>
                </FlexBox>
              )}
            />
          </MuiGrid>
          {apiMessageElement}
        </MuiGrid>
      </ExpandablePanel>
      <DialogWithHeader
        header="Add a peer striker"
        loading={loadingConnections}
        ref={addDialogRef}
        showClose
      >
        {peerConnections && (
          <PeerStrikerForm
            config={{
              initialValues: getPeerStrikerFormikInitialValues(),
              onSubmit: (values, helpers) => {
                const {
                  [INPUT_ID_PEER_STRIKER_PASSWORD]: password,
                  [INPUT_ID_PEER_STRIKER_PING_TEST]: ping,
                  [INPUT_ID_PEER_STRIKER_TARGET]: target,
                } = values;

                handleFormSubmit({
                  confirm,
                  getRequestBody: (): CreatePeerStrikerRequestBody => ({
                    ipAddress: target,
                    isPing: ping,
                    password,
                  }),
                  getSummary: () => ({
                    target,
                    password,
                    ping,
                  }),
                  header: `Add a peer striker with the following?`,
                  helpers,
                  onError: () => `Failed to add peer striker.`,
                  onSuccess: () => {
                    getConnections();

                    addDialogRef.current?.setOpen(false);

                    return `Successfully started peer striker registration.`;
                  },
                  operation: 'add',
                  url: `/host/connection`,
                  values,
                });
              },
              validationSchema: buildPeerStrikerSchema(peerConnections),
            }}
            operation="add"
          >
            <PeerStrikerInputGroup />
          </PeerStrikerForm>
        )}
      </DialogWithHeader>
      {confirm.confirmDialog}
    </>
  );
};

export type { ManagePeerStrikerProps };

export default ManagePeerStriker;
