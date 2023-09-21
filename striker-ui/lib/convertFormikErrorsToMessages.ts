const convertFormikErrorsToMessages = <Leaf extends string | undefined>(
  errors: Tree<Leaf>,
  {
    build = (mkey, err) => ({ children: err, type: 'warning' }),
    chain = '',
  }: {
    build?: (msgkey: keyof Tree, error: Leaf) => Messages[keyof Messages];
    chain?: keyof Tree<Leaf>;
  } = {},
): Messages =>
  Object.entries(errors).reduce<Messages>((previous, [key, value]) => {
    const extended = String(chain).length ? [chain, key].join('.') : key;

    if (typeof value === 'object') {
      return {
        ...previous,
        ...convertFormikErrorsToMessages(value, { chain: extended }),
      };
    }

    previous[extended] = build(extended, value);

    return previous;
  }, {});

export default convertFormikErrorsToMessages;
