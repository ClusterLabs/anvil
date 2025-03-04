/**
 * @property step - legacy compat value to specify which config step the value
 * belongs to. Assumes 1 when not given.
 */
type FormConfigEntry = {
  step?: number;
  value?: number | string;
};

type FormConfigData = Record<string, FormConfigEntry>;
