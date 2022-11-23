import { Grid } from '@mui/material';
import { FC, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import NETWORK_TYPES from '../../lib/consts/NETWORK_TYPES';

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
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';

const ConfigPeersForm: FC<ConfigPeerFormProps> = ({
  refreshInterval = 30000,
}) => {
  const { protect } = useProtect();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [apiMessage, setAPIMessage] = useProtectedState<Message | undefined>(
    undefined,
    protect,
  );
  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText: '',
      content: '',
      titleText: '',
    });
  const [inboundConnections, setInboundConnections] =
    useProtectedState<InboundConnectionList>({}, protect);
  const [isEditPeerConnections, setIsEditPeerConnections] =
    useState<boolean>(false);
  const [peerConnections, setPeerConnections] =
    useProtectedState<PeerConnectionList>({}, protect);

  const apiMessageElement = useMemo(
    () =>
      apiMessage ? (
        <Grid item sm={2} xs={1}>
          <MessageBox {...apiMessage} />
        </Grid>
      ) : undefined,
    [apiMessage],
  );

  const { isLoading } = periodicFetch<APIHostConnectionOverviewList>(
    `${API_BASE_URL}/host/connection`,
    {
      refreshInterval,
      onError: (error) => {
        setAPIMessage({
          children: `Failed to get connection data; CAUSE: ${error}`,
          type: 'error',
        });
      },
      onSuccess: ({
        local: {
          inbound: { ipAddress: ipAddressList, port: dbPort, user: dbUser },
          peer,
        },
      }) => {
        setInboundConnections(
          Object.entries(ipAddressList).reduce<InboundConnectionList>(
            (
              previous,
              [ipAddress, { networkLinkNumber, networkNumber, networkType }],
            ) => {
              previous[ipAddress] = {
                dbPort,
                dbUser,
                ipAddress,
                networkLinkNumber,
                networkNumber,
                networkType,
              };

              return previous;
            },
            {},
          ),
        );

        setPeerConnections(
          Object.entries(peer).reduce<PeerConnectionList>(
            (
              previous,
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
              previous[`${peerDBUser}@${peerIPAddress}:${peerDBPort}`] = {
                dbPort: peerDBPort,
                dbUser: peerDBUser,
                hostUUID,
                ipAddress: peerIPAddress,
                isPingTest,
              };

              return previous;
            },
            {},
          ),
        );
      },
    },
  );

  return (
    <>
      <ExpandablePanel
        header={<BodyText>Configure striker peers</BodyText>}
        loading={isLoading}
      >
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
                { dbPort, dbUser, networkNumber, networkType },
              ) => (
                <FlexBox spacing={0} sx={{ width: '100%' }}>
                  <MonoText>{`${dbUser}@${ipAddress}:${dbPort}`}</MonoText>
                  <SmallText>{`${NETWORK_TYPES[networkType]} ${networkNumber}`}</SmallText>
                </FlexBox>
              )}
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
              onDelete={() => {
                const pairs = Object.entries(peerConnections);
                const {
                  body: deleteRequestBody,
                  post: remainingPeerConnections,
                } = pairs.reduce<{
                  body: APIDeleteHostConnectionRequestBody;
                  post: PeerConnectionList;
                }>(
                  (previous, [key, value]) => {
                    const { hostUUID, isChecked } = value;

                    if (isChecked) {
                      previous.body.local.push(hostUUID);
                    } else {
                      previous.post[key] = value;
                    }

                    return previous;
                  },
                  { body: { local: [] }, post: {} },
                );
                const deleteCount = deleteRequestBody.local.length;

                if (deleteCount > 0) {
                  setConfirmDialogProps({
                    actionProceedText: 'Delete',
                    content: `The peer relationship between this striker and the selected ${deleteCount} host(s) will terminate. The removed peer(s) can be re-added later.`,
                    onProceedAppend: () => {
                      api
                        .delete('/host/connection', { data: deleteRequestBody })
                        .then(() => {
                          setPeerConnections(remainingPeerConnections);
                        })
                        .catch((error) => {
                          const emsg = handleAPIError(error);

                          emsg.children = (
                            <>
                              Failed to delete peer connection(s)&semi;
                              CAUSE&colon;
                              {emsg.children}
                            </>
                          );

                          setAPIMessage(emsg);
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
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ConfigPeersForm;
