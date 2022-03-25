import call from './call';

const join = (
  elements: string[] | string | undefined,
  { beforeReturn, elementWrapper = '', separator = '' }: JoinOptions = {},
) => {
  const joinSeparator = `${elementWrapper}${separator}${elementWrapper}`;

  const toReturn =
    elements instanceof Array && elements.length > 0
      ? `${elementWrapper}${elements.join(joinSeparator)}${elementWrapper}`
      : undefined;

  return call<string | undefined>(beforeReturn, {
    parameters: [toReturn],
    notCallableReturn: toReturn,
  });
};

export default join;
