const processNetworkData = (data: AnvilNetwork): ProcessedNetwork => {
  const processedBonds: string[] = [];
  const displayBonds: ProcessedNetwork = { bonds: [] };

  data?.hosts.forEach((host) => {
    host.bonds.forEach((bond) => {
      const index = processedBonds.findIndex(
        (processed: string) => processed === bond.bond_name,
      );

      if (index === -1) {
        processedBonds.push(bond.bond_name);
        displayBonds.bonds.push({
          bond_name: bond.bond_name,
          bond_uuid: bond.bond_uuid,
          bond_speed: 0,
          bond_state: 'degraded',
          hosts: [
            {
              host_name: host.host_name,
              host_uuid: host.host_uuid,
              link: bond.links[0].is_active ? bond.links[0] : bond.links[1],
            },
          ],
        });
      } else {
        displayBonds.bonds[index].hosts.push({
          host_name: host.host_name,
          host_uuid: host.host_uuid,
          link: bond.links[0].is_active ? bond.links[0] : bond.links[1],
        });
      }
    });
  });

  /* eslint-disable no-param-reassign */
  displayBonds.bonds.forEach((bond) => {
    const hostIndex =
      bond.hosts[0].link.link_speed > bond.hosts[1].link.link_speed ? 1 : 0;

    bond.bond_speed = bond.hosts[hostIndex].link.link_speed;
    bond.bond_state = bond.hosts[hostIndex].link.link_state;
  });
  return displayBonds;
};

export default processNetworkData;
