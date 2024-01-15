const getFormikErrorMessages = (
  errors: object,
  {
    build = (field, error) => ({ children: error, type: 'warning' }),
    chain = '',
    skip,
  }: {
    build?: (field: string, error: unknown) => Message;
    chain?: string;
    skip?: (field: string) => boolean;
  } = {},
): Messages =>
  Object.entries(errors).reduce<Messages>((previous, [key, value]) => {
    const field = [chain, key].filter((part) => Boolean(part)).join('.');

    if (value !== null && typeof value === 'object') {
      return {
        ...previous,
        ...getFormikErrorMessages(value, { build, chain: field, skip }),
      };
    }

    if (!skip?.call(null, field)) {
      previous[field] = build(field, value);
    }

    return previous;
  }, {});

export default getFormikErrorMessages;
