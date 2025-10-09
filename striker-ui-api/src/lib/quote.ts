import { un2n } from './un2n';

/**
 * Wraps a string in quotes.
 *
 * @param {string} value the string to wrap quotes around
 *
 * @param {string} options.char the character to wrap with; default: `"`
 *
 * @returns the string wrapped by quotes
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
    // calculated with `2 ^ n - 1`.
    //
    // Get the exponent to calculate the backslahes needed for the next layer.
    const exponent = un2n(backslashes.length + 1);

    // Simplify `2 ^ n - 1 + 1` because we need to include the quote's length.
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
