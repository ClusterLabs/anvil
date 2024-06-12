import { Grid } from '@mui/material';
import { FC, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

import AddPeerDialog from './AddPeerDialog';
import api from '../../lib/api';
import ConfirmDialog from '../ConfirmDialog';
import FlexBox from '../FlexBox';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import { ExpandablePanel } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import State from '../State';
import { BodyText, MonoText, SmallText } from '../Text';

const ConfigPeersForm: FC<ConfigPeerFormProps> = ({
  refreshInterval = 60000,
}) => {
  const addPeerDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [apiMessage, setApiMessage] = useState<Message | undefined>(undefined);
  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText: '',
      content: '',
      titleText: '',
    });
  const [inboundConnections, setInboundConnections] =
    useState<InboundConnectionList>({});
  const [isEditPeerConnections, setIsEditPeerConnections] =
    useState<boolean>(false);
  const [peerConnections, setPeerConnections] = useState<PeerConnectionList>(
    {},
  );

  const apiMessageElement = useMemo(
    () =>
      apiMessage && (
        <Grid item sm={2} xs={1}>
          <MessageBox {...apiMessage} />
        </Grid>
      ),
    [apiMessage],
  );

  const { isLoading } = periodicFetch<APIHostConnectionOverviewList>(
    `${API_BASE_URL}/host/connection`,
    {
      refreshInterval,
      onError: (error) => {
        setApiMessage({
          children: `Failed to get connection data. Error: ${error}`,
          type: 'error',
        });
      },
      onSuccess: ({
        local: {
          inbound: { ipAddress: ipAddressList, port: dbPort, user: dbUser },
          peer,
        },
      }) => {
        setInboundConnections((previous) =>
          Object.entries(ipAddressList).reduce<InboundConnectionList>(
            (
              nyu,
              [
                ipAddress,
                { ifaceId, networkLinkNumber, networkNumber, networkType },
              ],
            ) => {
              nyu[ipAddress] = {
                ...previous[ipAddress],
                dbPort,
                dbUser,
                ifaceId,
                ipAddress,
                networkLinkNumber,
                networkNumber,
                networkType,
              };

              return nyu;
            },
            {},
          ),
        );

        setPeerConnections((previous) =>
          Object.entries(peer).reduce<PeerConnectionList>(
            (
              nyu,
              [
                peerIPAddress,
                {
                  hostUUID,
                  isPing: isPingTest,
                  port: peerDBPort,
                  user: peerDBUser,
                },
              ],
            ) => {
              const peerKey = `${peerDBUser}@${peerIPAddress}:${peerDBPort}`;

              nyu[peerKey] = {
                ...previous[peerKey],
                dbPort: peerDBPort,
                dbUser: peerDBUser,
                hostUUID,
                ipAddress: peerIPAddress,
                isPingTest,
              };

              return nyu;
            },
            {},
          ),
        );
      },
    },
  );

  return (
    <>
      <ExpandablePanel header="Configure striker peers" loading={isLoading}>
        <Grid columns={{ xs: 1, sm: 2 }} container spacing="1em">
          <Grid item xs={1}>
            <List
              header="Inbound connections"
              listEmpty={
                <BodyText align="center">
                  No inbound connections found.
                </BodyText>
              }
              listItemKeyPrefix="config-peers-inbound-connection"
              listItems={inboundConnections}
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
          </Grid>
          <Grid item xs={1}>
            <List
              header="Peer connections"
              allowEdit
              edit={isEditPeerConnections}
              listEmpty={
                <BodyText align="center">No peer connections found.</BodyText>
              }
              listItemKeyPrefix="config-peers-peer-connection"
              listItems={peerConnections}
              onAdd={() => {
                addPeerDialogRef.current.setOpen?.call(null, true);
              }}
              onDelete={() => {
                const pairs = Object.entries(peerConnections);
                const deleteRequestBody =
                  pairs.reduce<APIDeleteHostConnectionRequestBody>(
                    (previous, [, { hostUUID, isChecked }]) => {
                      if (isChecked) {
                        previous.local.push(hostUUID);
                      }

                      return previous;
                    },
                    { local: [] },
                  );
                const deleteCount = deleteRequestBody.local.length;

                if (deleteCount > 0) {
                  setConfirmDialogProps({
                    actionProceedText: 'Delete',
                    content: `The peer relationship between this striker and the selected ${deleteCount} host(s) will terminate. The removed peer(s) can be re-added later.`,
                    onProceedAppend: () => {
                      api
                        .delete('/host/connection', { data: deleteRequestBody })
                        .catch((error) => {
                          const emsg = handleAPIError(error);

                          emsg.children = `Failed to delete peer connection(s). ${emsg.children}`;

                          setApiMessage(emsg);
                        });
                    },
                    proceedColour: 'red',
                    titleText: `Delete ${deleteCount} peer(s) from this striker?`,
                  });

                  confirmDialogRef.current.setOpen?.call(null, true);
                }
              }}
              onEdit={() => {
                setIsEditPeerConnections((previous) => !previous);
              }}
              onItemCheckboxChange={(key, event, isChecked) => {
                peerConnections[key].isChecked = isChecked;

                setPeerConnections((previous) => ({ ...previous }));
              }}
              renderListItem={(peer, { isPingTest = false }) => (
                <FlexBox row spacing={0}>
                  <FlexBox spacing={0}>
                    <MonoText>{peer}</MonoText>
                    <State label="Ping" state={isPingTest} />
                  </FlexBox>
                </FlexBox>
              )}
            />
          </Grid>
          {apiMessageElement}
        </Grid>
      </ExpandablePanel>
      <AddPeerDialog ref={addPeerDialogRef} />
      <ConfirmDialog
        closeOnProceed
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ConfigPeersForm;
