/**
 * @deprecated
 */
const testNotBlank: (args: MinimalInputTestArgs) => boolean = ({ value }) =>
  value ? String(value).length > 0 : false;

export default testNotBlank;
