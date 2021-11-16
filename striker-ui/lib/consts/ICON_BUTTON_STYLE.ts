import { BLACK, GREY, TEXT } from './DEFAULT_THEME';

const ICON_BUTTON_STYLE: Readonly<Record<string, unknown>> = {
  borderRadius: 8,
  backgroundColor: GREY,
  '&:hover': {
    backgroundColor: TEXT,
  },
  color: BLACK,
};

export default ICON_BUTTON_STYLE;
