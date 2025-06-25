import createForm from '../Form/FormFactory';
import { PeerStrikerFormikValues } from './schemas/buildPeerStrikerSchema';

type CreatePeerStrikerRequestBody = {
  ipAddress: string;
  isPing: boolean;
  password?: string;
  port?: string;
  sshPort?: string;
  user?: string;
};

const {
  Form: PeerStrikerForm,
  FormContext: PeerStrikerFormContext,
  useFormContext: usePeerStrikerFormContext,
} = createForm<PeerStrikerFormikValues>();

export type { CreatePeerStrikerRequestBody };

export { PeerStrikerFormContext, usePeerStrikerFormContext };

export default PeerStrikerForm;
