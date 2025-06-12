import disassembleCamel from './disassembleCamel';

const getFormikErrorMessages = (
  errors: object,
  {
    build = (field, error) => {
      let children: React.ReactNode = null;

      if (typeof error === 'string') {
        const [first, ...rest] = error.split(/\s+/);

        const name = disassembleCamel(first.replace(/^[^\s]+\.([^.]+)/, '$1'));

        children = [name, ...rest].join(' ');
      }

      return {
        children,
        type: 'warning',
      };
    },
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
