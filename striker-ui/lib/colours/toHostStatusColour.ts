import { BLUE, GREY, PURPLE } from '../consts/DEFAULT_THEME';

const colours: Record<string, string> = {
  offline: GREY,
  online: BLUE,
};

const toHostStatusColour = (status: string) => colours[status] || PURPLE;

export default toHostStatusColour;
