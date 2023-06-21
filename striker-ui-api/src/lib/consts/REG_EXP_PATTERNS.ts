export const P_HEX = '[[:xdigit:]]';
export const P_OCTET = '(?:25[0-5]|(?:2[0-4]|1[0-9]|[1-9]|)[0-9])';
export const P_ALPHANUM = '[a-z0-9]';
export const P_ALPHANUM_DASH = '[a-z0-9-]';
export const P_IPV4 = `(?:${P_OCTET}[.]){3}${P_OCTET}`;
export const P_UUID = `${P_HEX}{8}-${P_HEX}{4}-[1-5]${P_HEX}{3}-[89ab]${P_HEX}{3}-${P_HEX}{12}`;

export const REP_DOMAIN = new RegExp(
  `^(?:${P_ALPHANUM}(?:${P_ALPHANUM_DASH}{0,61}${P_ALPHANUM})?[.])+${P_ALPHANUM}${P_ALPHANUM_DASH}{0,61}${P_ALPHANUM}$`,
);

export const REP_INTEGER = /^\d+$/;

export const REP_IPV4 = new RegExp(`^${P_IPV4}$`);

export const REP_IPV4_CSV = new RegExp(`(?:${P_IPV4},)*${P_IPV4}`);

// Peaceful string is temporarily defined as a string without single-quote, double-quote, slash (/), backslash (\\), angle brackets (< >), and curly brackets ({ }).
export const REP_PEACEFUL_STRING = /^[^'"/\\><}{]+$/;

export const REP_UUID = new RegExp(`^${P_UUID}$`);
