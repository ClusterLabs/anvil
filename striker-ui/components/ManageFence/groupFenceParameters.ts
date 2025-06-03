const groupFenceParameters = (agent?: APIFenceSpec): FenceParameterGroups => {
  const result: FenceParameterGroups = {
    optional: {},
    required: {},
  };

  if (!agent) {
    return result;
  }

  const { parameters } = agent;

  const entries = Object.entries(parameters).sort(([a], [b]) =>
    a > b ? 1 : -1,
  );

  return entries.reduce<FenceParameterGroups>((previous, entry) => {
    const [id, parameter] = entry;

    let required = false;

    if (/plug|port/i.test(id)) {
      required = false;
    } else if (Number(parameter.required) === 1) {
      required = true;
    }

    const group: keyof typeof previous = required ? 'required' : 'optional';

    previous[group][id] = parameter;

    return previous;
  }, result);
};

export default groupFenceParameters;
