const toProvisionServerResources = (
  data: APIProvisionServerResources,
): ProvisionServerResources => {
  const { files, nodes, servers, storageGroups, subnodes } = data;

  return {
    files,
    nodes: Object.values(nodes).reduce<
      Record<string, ProvisionServerResourceNode>
    >((previous, node) => {
      const { memory, ...rest } = node;

      previous[node.uuid] = {
        ...rest,
        memory: {
          allocated: BigInt(memory.allocated),
          available: BigInt(memory.available),
          system: BigInt(memory.system),
          total: BigInt(memory.total),
        },
      };

      return previous;
    }, {}),
    servers: Object.values(servers).reduce<
      Record<string, ProvisionServerResourceServer>
    >((previous, server) => {
      const { memory, ...rest } = server;

      previous[server.uuid] = {
        ...rest,
        memory: {
          total: BigInt(memory.total),
        },
      };

      return previous;
    }, {}),
    storageGroups: Object.values(storageGroups).reduce<
      Record<string, ProvisionServerResourceStorageGroup>
    >((previous, sg) => {
      const { usage, ...rest } = sg;

      previous[sg.uuid] = {
        ...rest,
        usage: {
          free: BigInt(usage.free),
          total: BigInt(usage.total),
          used: BigInt(usage.used),
        },
      };

      return previous;
    }, {}),
    subnodes: Object.values(subnodes).reduce<
      Record<string, ProvisionServerResourceSubnode>
    >((previous, subnode) => {
      const { memory, ...rest } = subnode;

      previous[subnode.uuid] = {
        ...rest,
        memory: {
          total: BigInt(memory.total),
        },
      };

      return previous;
    }, {}),
  };
};

export default toProvisionServerResources;
