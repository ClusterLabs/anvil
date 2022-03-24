const join = (
  elements: string[] | undefined,
  { beforeReturn, elementWrapper = '', separator = '' }: JoinOptions,
) => {
  const joinSeparator = `${elementWrapper}${separator}${elementWrapper}`;

  const toReturn =
    elements instanceof Array && elements.length > 0
      ? `${elementWrapper}${elements.join(joinSeparator)}${elementWrapper}`
      : undefined;

  return typeof beforeReturn === 'function' ? beforeReturn(toReturn) : toReturn;
};

export default join;
