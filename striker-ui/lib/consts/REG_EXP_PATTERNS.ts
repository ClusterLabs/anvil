const alphanumeric = '[a-z0-9]';
const alphanumericDash = '[a-z0-9-]';
const octet = '(?:25[0-5]|(?:2[0-4]|1[0-9]|[1-9]|)[0-9])';

const ipv4 = `(?:${octet}[.]){3}${octet}`;

export const REP_DOMAIN = new RegExp(
  `^(?:${alphanumeric}(?:${alphanumericDash}{0,61}${alphanumeric})?[.])+${alphanumeric}${alphanumericDash}{0,61}${alphanumeric}$`,
);

export const REP_IPV4 = new RegExp(`^${ipv4}$`);

export const REP_IPV4_CSV = new RegExp(`(?:${ipv4},)*${ipv4}`);
