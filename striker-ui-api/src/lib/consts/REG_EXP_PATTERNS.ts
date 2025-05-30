export const P_HEX = '[a-f0-9]';
export const P_OCTET = '(?:25[0-5]|(?:2[0-4]|1[0-9]|[1-9]|)[0-9])';
export const P_ALPHANUM = '[a-z0-9]';
export const P_ALPHANUM_DASH = '[a-z0-9-]';

export const P_IPV4 = `(?:${P_OCTET}[.]){3}${P_OCTET}`;
export const P_LVM_UUID = `${P_ALPHANUM}{6}-(?:${P_ALPHANUM}{4}-){5}${P_ALPHANUM}{6}`;
export const P_UUID = `${P_HEX}{8}-(?:${P_HEX}{4}-){3}${P_HEX}{12}`;

const P_IFLINK = 'link\\d+';
const P_IFNUM = '\\d+';
const P_IFTYPE = '[a-z]+n';

const P_IFID = `${P_IFTYPE}${P_IFNUM}`;

export const P_IF = {
  full: `${P_IFID}_${P_IFLINK}`,
  id: P_IFID,
  link: P_IFLINK,
  num: P_IFNUM,
  type: P_IFTYPE,
  xLink: `${P_IFID}_(${P_IFLINK})`,
  xNum: `${P_IFTYPE}(${P_IFNUM})_${P_IFLINK}`,
  xType: `(${P_IFTYPE})${P_IFNUM}_${P_IFLINK}`,
};

export const REP_INTEGER = /^\d+$/;

export const REP_IPV4 = new RegExp(`^${P_IPV4}$`);

export const REP_IPV4_CSV = new RegExp(`(?:${P_IPV4},)*${P_IPV4}`);

export const REP_LVM_UUID = new RegExp(`^${P_LVM_UUID}$`, 'i');

export const REP_MAC = new RegExp(`^${P_HEX}{2}(?::${P_HEX}{2}){5}$`);

// Peaceful string is temporarily defined as a string without single-quote, double-quote, slash (/), backslash (\\), angle brackets (< >), and curly brackets ({ }).
export const REP_PEACEFUL_STRING = /^[^'"/\\><}{]+$/;

export const REP_UUID = new RegExp(`^${P_UUID}$`);
