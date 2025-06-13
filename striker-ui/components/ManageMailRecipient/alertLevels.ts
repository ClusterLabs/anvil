type AlertLevel = {
  label: string;
};

const alertLevels: Record<number, AlertLevel> = {
  1: {
    label: 'Critical',
  },
  2: {
    label: 'Warning',
  },
  3: {
    label: 'Notice',
  },
  4: {
    label: 'Info',
  },
};

export default alertLevels;
