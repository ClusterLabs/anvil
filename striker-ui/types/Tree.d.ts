type Tree<T = string> = {
  [k: string]: Tree<T> | T;
};
