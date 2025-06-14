const requiredFenceParameter = (
  id: string,
  parameter: APIFenceSpecParameter,
) => {
  let required: boolean = false;

  if (
    [
      /plug|port/i.test(id),
      Number(parameter.deprecated),
      parameter.replacement,
    ].some((cond) => Boolean(cond))
  ) {
    required = false;
  } else if (Number(parameter.required) === 1) {
    required = true;
  }

  return required;
};

export default requiredFenceParameter;
