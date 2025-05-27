import { BLUE, GREY, PURPLE } from '../consts/DEFAULT_THEME';

const colours: Record<string, string> = {
  none: GREY,
  offline: GREY,
  optimal: BLUE,
  syncing: GREY,
};

const toDrbdStatusColour = (status: string) => colours[status] || PURPLE;

export default toDrbdStatusColour;
