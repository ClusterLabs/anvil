const alphanumeric = '[a-z0-9]';
const alphanumericDash = '[a-z0-9-]';
const hex = '[0-9a-f]';
const octet = '(?:25[0-5]|(?:2[0-4]|1[0-9]|[1-9]|)[0-9])';

const ipv4 = `(?:${octet}[.]){3}${octet}`;

export const REP_DOMAIN = new RegExp(
  `^(?:${alphanumeric}(?:${alphanumericDash}{0,61}${alphanumeric})?[.])+${alphanumeric}${alphanumericDash}{0,61}${alphanumeric}$`,
);

export const REP_IPV4 = new RegExp(`^${ipv4}$`);

export const REP_IPV4_CSV = new RegExp(`^(?:${ipv4}\\s*,\\s*)*${ipv4}$`);

// Peaceful string is temporarily defined as a string without single-quote, double-quote, slash (/), backslash (\\), angle brackets (< >), and curly brackets ({ }).
export const REP_PEACEFUL_STRING = /^[^'"/\\><}{]+$/;

export const REP_UUID = new RegExp(
  `^${hex}{8}-${hex}{4}-[1-5]${hex}{3}-[89ab]${hex}{3}-${hex}{12}$`,
  'i',
);
