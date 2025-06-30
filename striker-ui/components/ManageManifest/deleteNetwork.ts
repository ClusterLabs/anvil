import { ManifestFormikValues } from './schemas/buildManifestSchema';

const deleteNetwork = (
  values: ManifestFormikValues,
  networkId: string,
): typeof values => {
  const result: typeof values = { ...values };

  const { [networkId]: rmNetwork, ...networks } = result.netconf.networks;

  result.netconf.networks = networks;

  Object.keys(result.hosts).forEach((hostSequence) => {
    const { [hostSequence]: host } = result.hosts;

    const { [networkId]: rmHostNetwork, ...hostNetworks } = host.networks;

    host.networks = hostNetworks;
  });

  return result;
};

export default deleteNetwork;
