import call from './call';

const join: JoinFunction = (
  elements,
  {
    beforeReturn,
    elementWrapper = '',
    fallback = '',
    onEach,
    separator = '',
  } = {},
) => {
  const joinSeparator = `${elementWrapper}${separator}${elementWrapper}`;

  const toReturn =
    elements instanceof Array && elements.length > 0
      ? `${elementWrapper}${elements.slice(1).reduce<string>(
          (previous, element) =>
            `${previous}${joinSeparator}${call<string>(onEach, {
              notCallableReturn: element,
              parameters: [element],
            })}`,
          call<string>(onEach, {
            notCallableReturn: elements[0],
            parameters: [elements[0]],
          }),
        )}${elementWrapper}`
      : fallback;

  return call<string>(beforeReturn, {
    notCallableReturn: toReturn,
    parameters: [toReturn],
  });
};

export default join;
