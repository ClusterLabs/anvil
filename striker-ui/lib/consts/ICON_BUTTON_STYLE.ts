import { BLACK, BORDER_RADIUS, GREY } from './DEFAULT_THEME';

const ICON_BUTTON_STYLE: Readonly<Record<string, unknown>> = {
  borderRadius: BORDER_RADIUS,
  backgroundColor: GREY,
  '&:hover': {
    backgroundColor: GREY,
  },
  color: BLACK,
};

export default ICON_BUTTON_STYLE;
