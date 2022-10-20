import call from './call';

const join: JoinFunction = (
  elements,
  {
    beforeReturn,
    elementWrapper = '',
    onEach = (element: string) => element,
    separator = '',
  } = {},
) => {
  const joinSeparator = `${elementWrapper}${separator}${elementWrapper}`;

  const toReturn =
    elements instanceof Array && elements.length > 0
      ? `${elementWrapper}${elements
          .slice(1)
          .reduce<string>(
            (previous, element) =>
              `${previous}${joinSeparator}${onEach(element)}`,
            elements[0],
          )}${elementWrapper}`
      : undefined;

  return call<string | undefined>(beforeReturn, {
    parameters: [toReturn],
    notCallableReturn: toReturn,
  });
};

export default join;
