
CREATE TABLE regist_form (
   no       INTEGER NOT NULL,
   email    CHAR(128) NOT NULL,
   password CHAR(32) NOT NULL,
   name     CHAR(32) NOT NULL,
   nick     CHAR(32) NOT NULL,
   phone    CHAR(16) NOT NULL,
   tshirt   CHAR(4) NOT NULL,
   confirm  CHAR(32) NOT NULL,
   digest   VARCHAR(255),
   type     CHAR(8) NOT NULL,
   location VARCHAR(255),
   comment  TEXT,
   created_on DATETIME NOT NULL,
   updated_on DATETIME NOT NULL,
   primary key(no),
   unique(email)
);

CREATE TABLE epilogue (
   id  	     INTEGER NOT NULL,
   user_id   INTEGER NOT NULL,
   title     TEXT NOT NULL,
   content   LONGTEXT NOT NULL,
   created_on DATETIME NOT NULL,
   updated_on DATETIME NOT NULL,
   primary key(id)
);