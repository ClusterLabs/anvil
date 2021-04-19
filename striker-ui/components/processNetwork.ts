const processNetworkData = (data: AnvilNetwork): ProcessedNetwork => {
  const processedBonds: string[] = [];
  const thingy: ProcessedNetwork = { bonds: [] };

  data?.nodes.forEach((node) => {
    node.bonds.forEach((bond) => {
      const index = processedBonds.findIndex(
        (processed: string) => processed === bond.bond_name,
      );

      if (index === -1) {
        processedBonds.push(bond.bond_name);
        thingy.bonds.push({
          bond_name: bond.bond_name,
          bond_uuid: bond.bond_uuid,
          nodes: [
            {
              host_name: node.host_name,
              host_uuid: node.host_uuid,
              link: bond.links[0].is_active ? bond.links[0] : bond.links[1],
            },
          ],
        });
      } else {
        thingy.bonds[index].nodes.push({
          host_name: node.host_name,
          host_uuid: node.host_uuid,
          link: bond.links[0].is_active ? bond.links[0] : bond.links[1],
        });
      }
    });
  });
  return thingy;
};

export default processNetworkData;
