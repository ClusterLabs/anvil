export const sqlAlertOverrides = () => {
  const sql = `
    SELECT *
    FROM alert_overrides
    WHERE alert_override_alert_level != -1`;

  return sql;
};
