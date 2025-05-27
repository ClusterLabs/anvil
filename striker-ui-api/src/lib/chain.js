/**
 * Checks whether `value` is an object.
 * @param {any} value
 * @returns true when `value` is an object; false otherwise
 */
const isObject = (value) => typeof value === 'object' && value !== null;

/**
 * Puts the `value` at the path described by `chain`.
 *
 * It's a JS module because there are too many TS type issues at the time of
 * writing. It should be moved back to TS once time permits.
 * @param {(number | string | symbol)[]} chain
 * @param {any} value
 * @param {any} parent
 * @returns `parent`
 */
export const setChain = (chain, value, parent = {}) => {
  const { 0: key, length } = chain;

  if ([null, undefined].includes(key) || !isObject(parent)) {
    return parent;
  }

  const { [key]: existing } = parent;

  if (length > 1 && (existing === undefined || isObject(existing))) {
    parent[key] = setChain(chain.slice(1), value, existing);
  } else {
    parent[key] = value;
  }

  return parent;
};
