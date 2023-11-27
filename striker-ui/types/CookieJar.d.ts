type CookieJar = Record<string, unknown>;

type SessionCookieUser = {
  name: string;
  uuid: string;
};

type SessionCookie = {
  expires: string;
  user: SessionCookieUser;
};
