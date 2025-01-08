type PreferencesCookie = {
  dashboard: {
    servers: {
      view: 'list' | 'previews';
    };
  };
};

type SessionCookieUser = {
  name: string;
  uuid: string;
};

type SessionCookie = {
  expires: string;
  user: SessionCookieUser;
};
