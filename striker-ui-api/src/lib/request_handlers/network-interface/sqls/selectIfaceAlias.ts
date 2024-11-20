const repLink = 'link\\d+';
const repNum = '\\d+';
const repType = '[a-z]+n';

const repId = `${repType}${repNum}`;

export const ifaceAliasReps = {
  full: `${repId}_${repLink}`,
  id: repId,
  link: repLink,
  num: repNum,
  type: repType,
  xLink: `${repId}_(${repLink})`,
  xNum: `${repType}(${repNum})_${repLink}`,
  xType: `(${repType})${repNum}_${repLink}`,
};

export const selectIfaceAlias = () =>
  `SELECT
      network_interface_uuid,
      CASE
        WHEN network_interface_name ~* '${ifaceAliasReps.full}'
          THEN network_interface_name
        ELSE network_interface_device
      END AS network_interface_alias
    FROM network_interfaces`;
