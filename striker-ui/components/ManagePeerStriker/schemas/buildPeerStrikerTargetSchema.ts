import * as yup from 'yup';

import { yupGetNotOneOf } from '../../../lib/yupCommons';

const buildPeerStrikerTargetSchema = (
  skip: null | string,
  peers: PeerConnectionList,
) => {
  let filterBy: ((peer: PeerConnection) => boolean) | undefined;

  if (skip) {
    filterBy = (peer) => peer.hostUUID !== skip;
  }

  const targets = yupGetNotOneOf<PeerConnection>(
    peers,
    (peer) => peer.ipAddress,
    { filterBy },
  );

  return yup.string().notOneOf(targets, '${path} already connected');
};

export default buildPeerStrikerTargetSchema;
