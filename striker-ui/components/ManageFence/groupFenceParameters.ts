import requiredFenceParameter from './requiredFenceParameter';

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
    a.localeCompare(b),
  );

  return entries.reduce<FenceParameterGroups>((previous, entry) => {
    const [id, parameter] = entry;

    const required = requiredFenceParameter(id, parameter);

    const group: keyof typeof previous = required ? 'required' : 'optional';

    previous[group][id] = parameter;

    return previous;
  }, result);
};

export default groupFenceParameters;
