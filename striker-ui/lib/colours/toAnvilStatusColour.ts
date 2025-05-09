import { BLUE, GREY, PURPLE } from '../consts/DEFAULT_THEME';

const colours: Record<string, string> = {
  offline: GREY,
  optimal: BLUE,
};

const toAnvilStatusColour = (status: string) => colours[status] || PURPLE;

export default toAnvilStatusColour;
