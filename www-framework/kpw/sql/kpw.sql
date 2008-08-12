
CREATE TABLE regist_form (
   no       INTEGER NOT NULL,
   email    CHAR(128) NOT NULL,
   password CHAR(32) NOT NULL,
   name     CHAR(32) NOT NULL,
   nick     CHAR(32) NOT NULL,
   phone    CHAR(16) NOT NULL,
   tshirt   CHAR(4) NOT NULL,
   confirm  CHAR(32) NOT NULL,
   primary key(no, email)
);
