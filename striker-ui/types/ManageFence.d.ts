type FenceParameter = {
  value: boolean | number | string;
};

type FenceFormikValues = {
  agent: null | string;
  name: string;
  parameters: Record<string, FenceParameter>;
  uuid: string;
};

type FenceParameterGroups = Pick<
  Record<string, APIFenceSpecParameterList>,
  'optional' | 'required'
>;
