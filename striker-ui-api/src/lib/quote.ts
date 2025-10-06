import { un2n } from './un2n';

/**
 * FROM SANDBOX:
 *
 *  ivt = (value) => { let x = value; let n = 0; while (x > 0) { x >>= 1; n += 1; } return n; }
 *
 *  quote = (value) => {
      const encoded = encodeURIComponent(value);
      const matches = encoded.matchAll(/(?:%5C)*(?:%22)/g);
      console.dir({ matches });
      if (!matches) return value;
      let previous = encoded;
      let offset = 0;
      for (const match of matches) {
          console.dir({ match });
          const before = match[0];
          console.dir({ previous, before });
          const backslashes = before.match(/(?:%5C)/g) ?? [];
          console.dir({ backslashes });
          const exponent = ivt(backslashes.length + 1);
          console.dir({ exponent });
          const lengthAfter = Math.pow(2, exponent) * 3;
          console.dir({ lengthAfter });
          const after = '%22'.padStart(lengthAfter, '%5C');
          console.dir({ after });
          previous = `${previous.slice(0, match.index + offset)}${after}${previous.slice(match.index + offset + before.length)}`;
          console.dir({ previous });
          offset += lengthAfter - before.length;
          console.dir({ offset });
      }
      return decodeURIComponent(`%22${previous}%22`);
    };
  */
export const quote = (
  value: string,
  options: {
    char?: '"' | "'";
  } = {},
): string => {
  const { char = '"' } = options;

  // Work with encoded strings to avoid losing backslashes when moving values
  // between string.
  const encoded = {
    backslash: '%5C',
    quote: encodeURIComponent(char),
    value: encodeURIComponent(value),
  };

  const allBackslashes = new RegExp(`(?:${encoded.backslash})`, 'g');

  const allQuotes = new RegExp(
    `(?:${encoded.backslash})*(?:${encoded.quote})`,
    'g',
  );

  const matches = encoded.value.matchAll(allQuotes);

  if (!matches) {
    return value;
  }

  let previous: string = encoded.value;

  let offset = 0;

  let match: RegExpExecArray | null;

  while ((match = allQuotes.exec(encoded.value)) !== null) {
    const { [0]: before, index: indexBefore } = match;

    const backslashes = before.match(allBackslashes) ?? [];

    // The number of backslashes needed in each "quoted layer" can be
    // calculated with `2 ^ n - 1`

    const exponent = un2n(backslashes.length + 1);

    const lengthAfter = Math.pow(2, exponent) * encoded.backslash.length;

    const after = encoded.quote.padStart(lengthAfter, encoded.backslash);

    const cutAtIndex = indexBefore + offset;

    const head = previous.slice(0, cutAtIndex);

    const tail = previous.slice(cutAtIndex + before.length);

    previous = `${head}${after}${tail}`;

    offset += lengthAfter - before.length;
  }

  previous = decodeURIComponent(`${encoded.quote}${previous}${encoded.quote}`);

  return previous;
};
