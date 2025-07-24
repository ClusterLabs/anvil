import { BLUE, GREY, PURPLE } from '../consts/DEFAULT_THEME';

const colours: Record<string, string> = {
  online: BLUE,
  'powered off': GREY,
};

const toHostStatusColour = (status: string) => colours[status] || PURPLE;

export default toHostStatusColour;
