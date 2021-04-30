const processNetworkData = (data: AnvilNetwork): ProcessedNetwork => {
  const processedBonds: string[] = [];
  const displayBonds: ProcessedNetwork = { bonds: [] };

  data?.nodes.forEach((node) => {
    node.bonds.forEach((bond) => {
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
          nodes: [
            {
              host_name: node.host_name,
              host_uuid: node.host_uuid,
              link: bond.links[0].is_active ? bond.links[0] : bond.links[1],
            },
          ],
        });
      } else {
        displayBonds.bonds[index].nodes.push({
          host_name: node.host_name,
          host_uuid: node.host_uuid,
          link: bond.links[0].is_active ? bond.links[0] : bond.links[1],
        });
      }
    });
  });

  /* eslint-disable no-param-reassign */
  displayBonds.bonds.forEach((bond) => {
    const nodeIndex =
      bond.nodes[0].link.link_speed > bond.nodes[1].link.link_speed ? 1 : 0;

    bond.bond_speed = bond.nodes[nodeIndex].link.link_speed;
    bond.bond_state = bond.nodes[nodeIndex].link.link_state;
  });
  return displayBonds;
};

export default processNetworkData;
