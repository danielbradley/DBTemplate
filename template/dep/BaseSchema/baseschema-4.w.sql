#
# BaseSchema v4.w
# Copyright 2016-2021, Cross Adaptive
#
# Last modified - 2021-11-26T13:32:41+10:00
#

DELIMITER //
CREATE FUNCTION IsEventScheduler
()
RETURNS BOOL
DETERMINISTIC
BEGIN

DECLARE $USER TEXT;

SET $USER = USER();

return ($USER = 'event_scheduler@localhost' );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IsLocalCaller
()
RETURNS BOOL
DETERMINISTIC
BEGIN

DECLARE $USER TEXT;

SET $USER = USER();

return NOT $USER = 'public@localhost' AND ($USER LIKE '%@localhost' OR IsRootCaller() OR IsEventScheduler());

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IsLocalRootCaller
()
RETURNS BOOL
DETERMINISTIC
BEGIN

DECLARE $USER TEXT;

SET $USER = USER();

return ($USER = 'root@localhost' );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IsRootCaller
()
RETURNS BOOL
DETERMINISTIC
BEGIN

DECLARE $USER TEXT;

SET $USER = USER();

return ($USER LIKE 'root@%' );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION GenerateSalt
()
RETURNS CHAR(64)
DETERMINISTIC
BEGIN

DECLARE salt CHAR(64);

SET salt = RAND();

SET salt = SHA2( salt, 256 );

return salt;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ComputeHash
(
  salt           CHAR(64),
  value          TEXT
)
RETURNS CHAR(64)
DETERMINISTIC
BEGIN

DECLARE enckey TEXT;
DECLARE string TEXT;
DECLARE hash   CHAR(64);

#
#   This value has now been hardcoded to deal with the deprecation
#   of DES_ENCRYPT, which used to allow mingled encryption with an external key.
#   This should be the value that would have been used if no external key was used.
#

SET enckey = "a514e1386e06661c1ca48b87dbada4d010b8149adca8b827c7fc23e2c49ad061";
SET string = CONCAT( enckey, salt, value );
SET hash   = SHA2( string, 256 );

return hash;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION MyDecrypt
(
  enckey            TEXT,
  encvalue          TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

DECLARE hashkey TEXT;

IF "" != encvalue THEN

  #
  #   This value has now been hardcoded to deal with the deprecation
  #   of DES_ENCRYPT, which used to allow mingled encryption with an external key.
  #   This should be the value that would have been used if no external key was used.
  #

  SET hashkey = "a514e1386e06661c1ca48b87dbada4d010b8149adca8b827c7fc23e2c49ad061";

  return AES_DECRYPT( UNHEX( encvalue ), hashkey );

ELSE

  return "";

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION MyEncrypt
(
  $enckey         TEXT,
  $value          TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

DECLARE $hashkey TEXT;

IF "" != $value THEN

    #
    #   This value has now been hardcoded to deal with the deprecation
    #   of DES_ENCRYPT, which used to allow mingled encryption with an external key.
    #   This should be the value that would have been used if no external key was used.
    #

    SET $hashkey = "a514e1386e06661c1ca48b87dbada4d010b8149adca8b827c7fc23e2c49ad061";

    return HEX( AES_ENCRYPT( $value, $hashkey ) );

ELSE

    return "";

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION RandomNumber
(
    $max  INT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

    DECLARE $text  TEXT  DEFAULT '';
    DECLARE $len   INT   DEFAULT  0;

    SET $text = $max;
    SET $len  = LENGTH( $text );
    SET $text = FLOOR( RAND() * $max );

    return LPAD( $text, $len, '0' );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION GetTimeZone
()
RETURNS CHAR(6)
DETERMINISTIC
BEGIN

DECLARE $diff TIME DEFAULT 0;

SET $diff = TIMEDIFF(NOW(), UTC_TIMESTAMP);

IF 0 <= $diff THEN
  return CONCAT( "+", $diff );
ELSE
  return $diff;
END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION AsAppleTime
(
  $datetime DATETIME
)
RETURNS TEXT
DETERMINISTIC
BEGIN

return CONCAT( DATE( $datetime ), "T", TIME( $datetime ), ".000", GetTimeZone() );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ConvertZoneToTime
(
  $zone CHAR(6)
)
RETURNS TIME
DETERMINISTIC
BEGIN

return CONVERT( REPLACE( $zone, "+", " " ), TIME );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ConvertTo
(
  $datetime DATETIME
)
RETURNS DATETIME
DETERMINISTIC
BEGIN

DECLARE $dx DATETIME DEFAULT 0;

SET $dx = DATE_SUB( $datetime, INTERVAL 1 HOUR );

return $dx;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ConvertToLocalTimeZone
(
  $appletime CHAR(29)
)
RETURNS DATETIME
DETERMINISTIC
BEGIN

# 2014-12-30T10:00:00.000+10:00

DECLARE $len           INT;
DECLARE $tmp      CHAR(29);
DECLARE $datetime DATETIME;
DECLARE $zone      CHAR(6);
DECLARE $test         TEXT;

SET $zone = "";
SET $test = "";

IF "" != $appletime THEN

  SET $len = LENGTH( $appletime );

  IF 10 = $len THEN

    SET $datetime = CONVERT( $appletime, DATETIME );
    SET $test     = CONCAT_WS( "|", $datetime );

  ELSEIF 19 = $len OR 23 = $len THEN

    SET $tmp      = REPLACE( $appletime, "T", " " );
    SET $tmp      = SUBSTRING( $tmp, 1, 19 );
    SET $datetime = CONVERT( $tmp, DATETIME );
    SET $test     = CONCAT_WS( "|", $datetime );

  ELSEIF 19 = $len OR 23 = $len THEN

    SET $tmp      = REPLACE( $appletime, "T", " " );
    SET $tmp      = SUBSTRING( $tmp, 1, 19 );
    SET $datetime = CONVERT( $tmp, DATETIME );
    SET $test     = CONCAT_WS( "|", $datetime );

  ELSEIF 25 <= $len THEN

    SET $tmp      = REPLACE( $appletime, "T", " " );
    SET $tmp      = SUBSTRING( $tmp, 1, 19 );
    SET $datetime = CONVERT( $tmp, DATETIME );
    SET $zone     = SUBSTRING( $appletime, -6 );
    SET $zone     = REPLACE( $zone, ' ', '+' );
    SET $datetime = CONVERT_TZ( $datetime, $zone, GetTimeZone() );
    SET $test     = CONCAT_WS( "|", $tmp, $datetime, $zone, GetTimeZone() );

    #IF NULL = $datetime THEN
    #  SET $datetime = 0;
    #END IF;

  ELSE

    SET $test = "Wrong length";
    SET $datetime = 1;

  END IF;

ELSE

  SET $datetime = 2;

END IF;

return $datetime;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ConvertWeekToDate
(
  $year YEAR,
  $week INT(2)
)
RETURNS DATE
DETERMINISTIC
BEGIN

DECLARE $date_string   TEXT;
DECLARE $start_of_week DATE;

SET $date_string = CONCAT( $year, $week, " MONDAY" );

return STR_TO_DATE( $date_string, '%X%V %W' );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION GetTime
(
   $datetime TEXT
)
RETURNS TIME
DETERMINISTIC
BEGIN

DECLARE $time TIME DEFAULT 0;
DECLARE $one  CHAR(10);
DECLARE $two  CHAR(10);
DECLARE $use  CHAR(10);

SET $one = GET_JTH( $datetime, " ", 1 );
SET $two = GET_JTH( $datetime, " ", 2 );

IF "" != $two THEN

    SET $use = $two;

ELSE

    SET $use = $one;

END IF;

IF 4 = LENGTH( $use ) THEN

    SET $time = CONCAT( SUBSTR( $use, 1, 2 ), ":", SUBSTR( $use, 3, 2 ), ":00" );

ELSEIF 5 = LENGTH( $use ) THEN

    SET $time = CONCAT( $use, ":00" );

ELSEIF 8 = LENGTH( $use ) THEN

    SET $time = $use;

ELSE

    SET $time = "12:59:59";

END IF;

return $time;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION DateOfNextDayname
(
    $date         DATE,
    $dayname      CHAR(3)
)
RETURNS DATE
DETERMINISTIC
BEGIN

#
# YEARWEEK( 2017-02-08 ) = '201706'
#
# STR_TO_DATE( CONCAT( '201706', ' ', 'Wed' ), '%X%V %a' ) = '2017-02-08'
#
# DATE_ADD( '2017-02-08', INTERVAL 1 WEEK ) = '2017-02-15'
#

DECLARE $date_of_dayname_in_this_week  DATE  DEFAULT 0;
DECLARE $date_of_next_dayname          DATE  DEFAULT 0;

SET $date_of_dayname_in_this_week = STR_TO_DATE( CONCAT( YEARWEEK( $date ), ' ', $dayname ), '%X%V %a' );

IF $date <= $date_of_dayname_in_this_week THEN

    SET $date_of_next_dayname = $date_of_dayname_in_this_week;

ELSE

    SET $date_of_next_dayname = STR_TO_DATE( CONCAT( YEARWEEK( DATE_ADD( $date, INTERVAL 1 WEEK ) ), ' ', $dayname ), '%X%V %a' );

END IF;

return $date_of_next_dayname;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION CallToString
(
    $sep   CHAR,
    $list  TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

    DECLARE $ret    TEXT  DEFAULT '';
    DECLARE $next   TEXT  DEFAULT '';
    DECLARE $i      INT   DEFAULT  0;
    DECLARE $count  INT   DEFAULT  0;

    #
    #   Determine the number of separators and therefore parameters.
    #
    SET $count = LENGTH( $list ) - LENGTH( REPLACE( $list, $sep, "" ) ) + 1;

    WHILE $i < $count
    DO

        SET $i = $i + 1;

        SET $next = GetJth( $list, $sep, $i );

        IF $i = 1 THEN
            IF $next = "" THEN
                SET $ret = NULL;                                # NULL
            ELSE
                SET $ret = CONCAT( $ret, $next, '(' );          # Magic(
            END IF;
        ELSE
            IF $i = $count AND $i = 2 THEN
                SET $ret = CONCAT( $ret, ")" );                 # Magic()
            ELSEIF $i = 2 THEN
                SET $ret = CONCAT( $ret, " '", $next, "'" );    # Magic( 'XXX'
            ELSEIF $i > 2 AND $i < $count THEN
                SET $ret = CONCAT( $ret, ", '", $next, "'" );   # Magic( 'XXX', 'YYY'
            ELSEIF $i = $count THEN
                SET $ret = CONCAT( $ret, ", '", $next, "' )" ); # Magic( 'XXX', 'YYY' )
            END IF;
        END IF;

    END WHILE;

    return $ret;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION DecodeHTMLEntities
(
    $text LONGTEXT
)
RETURNS LONGTEXT
DETERMINISTIC
BEGIN

SET $text = REPLACE( $text, '&amp;', '!!AMP!!' );

IF INSTR( $text, '&' ) THEN
    SET $text = REPLACE( $text, '&apos;', "'" );
    SET $text = REPLACE( $text, '&#039;', "'" );
    SET $text = REPLACE( $text, '&quot;', '"' );
    SET $text = REPLACE( $text, '&lt;',   '<' );
    SET $text = REPLACE( $text, '&gt;',   '>' );
    SET $text = REPLACE( $text, '&nbsp;', ' ' );
END IF;

SET $text = REPLACE( $text, '!!AMP!!', '&' );

return $text;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION GetJth
(
  $Text                   LONGTEXT,
  $Delimiter              TEXT,
  $I                      INT(11)
)
RETURNS LONGTEXT
DETERMINISTIC
BEGIN

DECLARE $tmp      LONGTEXT  DEFAULT '';
DECLARE $ret      LONGTEXT  DEFAULT '';
DECLARE $test     LONGTEXT  DEFAULT '';

IF 0 = LENGTH( $Delimiter ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EMPTY_DELIMITER';

END IF;

#
#    Compare whether substring returned is same for i and i-1.
#    If so have run out of components, set return as "".
#

SET $tmp  = SUBSTRING_INDEX( $Text, $Delimiter, $I );
SET $test = SUBSTRING_INDEX( $Text, $Delimiter, $I - 1 );

IF $tmp != $test THEN

    SET $ret = SUBSTRING_INDEX( $tmp, $Delimiter, -1 );

END IF;

RETURN $ret;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ReplaceWith
(
    $content     LONGTEXT,
    $delimiter   TEXT,
    $equals      TEXT,
    $dictionary  LONGTEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

    DECLARE $keypair  LONGTEXT  DEFAULT '';
    DECLARE $key      LONGTEXT  DEFAULT '';
    DECLARE $val      LONGTEXT  DEFAULT '';
    DECLARE $i        INT       DEFAULT  1;

lp: WHILE TRUE DO

        SET $keypair = GetJth( $dictionary, $delimiter, $i ); 

        IF "" = $keypair THEN

            LEAVE lp;

        ELSE

            SET $key = CONCAT( '%', TRIM( GetJth( $keypair, $equals, 1 ) ), '%' );
            SET $val =              TRIM( GetJth( $keypair, $equals, 2 ) );

            SET $content = REPLACE( $content, $key, $val );

        END IF;

        SET $i = $i + 1;

    END WHILE;

    return $content;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ExtractUser
(
    $email  TEXT
)
RETURNS TEXT CHARSET latin1
DETERMINISTIC
BEGIN

    SET $email = LOWER( $email );
    SET $email = SUBSTRING_INDEX( $email, '@', 1 );

    return CONCAT( '%', $email, '%' );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION CalculatePasswordStrength
(
    $password  TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

    DECLARE $strength ENUM( "NONE", "WEAK", "MEDIUM", "STRONG", "ULTRA" );
    DECLARE $length   INT  DEFAULT 0;

    SET $strength = "NONE";
    SET $length   = LENGTH( $password );

    IF     $length > 20 THEN  SET $strength = "ULTRA";
    ELSEIF $length > 15 THEN  SET $strength = "STRONG";
    ELSEIF $length >  7 THEN  SET $strength = "MEDIUM";
    ELSE                      SET $strength = "WEAK";
    END IF;

    IF EXISTS( SELECT * FROM base_users WHERE NOT email='' AND LOWER( $password ) LIKE ExtractUser( email ) ) THEN
        SET $strength = "WEAK";
    END IF;

    IF "MEDIUM" = $strength THEN

        #
        #   Test for uppercase
        #

        IF BINARY $password = BINARY UPPER( $password )  THEN
            SET $strength = "WEAK";
        END IF;

        #
        #   Test for lowercase
        #

        IF BINARY $password = BINARY LOWER( $password ) THEN
            SET $strength = "WEAK";
        END IF;

        #
        #   Test for numeral
        #

        IF NOT $password REGEXP '[0-9]' THEN
            SET $strength = "WEAK";
        END IF;

        #
        #   Test for symbol
        #

        IF NOT $password REGEXP '~|`|!|@|#|\\$|%|\\^|&|\\*|\\(|\\)|_|-|\\+|=|\\{|\\}|\\[|\\]|\\||:|;|"|\'|<|,|>|\\.|\\?|/' THEN
            SET $strength = "WEAK";
        END IF;

    END IF;

    return $strength;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION CalculatePasswordStrength_Old
(
    $password  TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

    DECLARE $strength ENUM( "NONE", "WEAK", "MEDIUM", "STRONG", "ULTRA" );
    DECLARE $length   INT  DEFAULT 0;

    SET $length = LENGTH( $password );

    IF     $length > 20 THEN  SET $strength = "ULTRA";
    ELSEIF $length > 15 THEN  SET $strength = "STRONG";
    ELSEIF $length >  5 THEN  SET $strength = "MEDIUM";
    ELSE                      SET $strength = "WEAK";
    END IF;

    return $strength;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Title
(
    $text  TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

    DECLARE $title  TEXT  DEFAULT '';
    DECLARE $word   TEXT  DEFAULT '';
    DECLARE $i      INT   DEFAULT  0;

    SET $title = "";

    REPEAT

        SET $i    = $i + 1;
        SET $word = GetJth( $text, ' ', $i );

        SET $title = CONCAT( $title, ' ', SUBSTRING( $word, 1, 1 ), LOWER( SUBSTRING( $word, 2 ) ) );

    UNTIL "" = $word END REPEAT;

    return TRIM( $title );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE CheckLimitOffset
(
INOUT $limit                       INT(11),
INOUT $offset                      INT(11)
)
DETERMINISTIC
SQL SECURITY INVOKER
BEGIN

IF "" = $limit THEN
  SET $limit = 1000000;
END IF;

IF "" = $offset THEN
  SET $offset = 0;
END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IfEmpty
(
  $text1          TEXT,
  $text2          TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

IF ISNULL($text1) OR '' = TRIM($text1) THEN

    return $text2;

ELSE

    return $text1;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IfNoDate
(
  $date       DATE,
  $alternate  DATE
)
RETURNS DATE
DETERMINISTIC
BEGIN

IF 0 = $date OR ISNULL($date) THEN

    return $alternate;

ELSE

    return $date;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IfNone
(
  $date       DATETIME,
  $alternate  DATETIME
)
RETURNS DATETIME
DETERMINISTIC
BEGIN

IF 0 = $date OR ISNULL($date) THEN

    return $alternate;

ELSE

    return $date;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IfVoid
(
  $text1          TEXT,
  $text2          TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

IF '' = $text1 THEN

    return $text2;

ELSE

    return $text1;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IfZero
(
  $id1         INT(11),
  $id2         INT(11)
)
RETURNS INT(11)
DETERMINISTIC
BEGIN

IF 0 = $id1 THEN

    return $id2;

ELSE

    return $id1;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION OrNull
(
  $text         TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN

IF '' = TRIM( $text ) THEN

    return NULL;

ELSE

    return $text;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION IsReadOnly
()
RETURNS BOOLEAN
READS SQL DATA
BEGIN

DECLARE $read_only BOOLEAN DEFAULT 0;

SELECT @@global.read_only INTO $read_only;

return $read_only;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION ReadOnly
()
RETURNS BOOL
READS SQL DATA
BEGIN

DECLARE $readonly BOOLEAN DEFAULT 0;

IF @@read_only THEN

  SET $readonly = 1;

END IF;

return $readonly;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Retrieve_Parameters_For
(
  $database                   CHAR(64),
  $name                       CHAR(99)
)
RETURNS TEXT
READS SQL DATA
BEGIN

    return RetrieveParametersFor( $database, $name );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION RetrieveParametersFor
(
  $database                   CHAR(64),
  $name                       CHAR(99)
)
RETURNS TEXT
READS SQL DATA
BEGIN

    DECLARE $ret  TEXT;
    DECLARE $ver  INT  DEFAULT 0;

    SET $ver = GetJth( @@VERSION, '.', 1 );

    IF 5 = $ver THEN

        SELECT
          param_list

        INTO
          $ret

        FROM mysql.proc
        WHERE db            =  $database
        AND   name          =  $name
        AND   type          = 'PROCEDURE'
        AND   security_type = 'DEFINER'
        AND   comment       = 'EXPORT'
        ORDER BY modified DESC LIMIT 1;

        return $ret;

    ELSE
        return RetrieveParametersFor_Slow( $database, $name );
    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION RetrieveParametersFor_Slow
(
    $database  CHAR(64),
    $name      CHAR(99)
)
RETURNS TEXT
READS SQL DATA
BEGIN

    DECLARE $ret TEXT DEFAULT '';

    IF EXISTS
    (
        SELECT *
        FROM   information_schema.ROUTINES
        WHERE  ROUTINE_SCHEMA  = $database
        AND    ROUTINE_NAME    = $name
        AND    ROUTINE_TYPE    = 'PROCEDURE'
        AND    ROUTINE_COMMENT = 'EXPORT'
        AND    SECURITY_TYPE   = 'DEFINER'
    )
    THEN

        SELECT
            GROUP_CONCAT( parameter ) INTO $ret

        FROM
        (
            SELECT
                SPECIFIC_SCHEMA,
                SPECIFIC_NAME,
                CONCAT( ' ', PARAMETER_NAME, ' ', UPPER( DATA_TYPE ) ) AS parameter

            FROM  information_schema.parameters
            WHERE SPECIFIC_SCHEMA = $database
            AND   SPECIFIC_NAME   = $name
            AND   ORDINAL_POSITION > 0 # Ignore return
            ORDER BY ORDINAL_POSITION

        ) AS S0
        GROUP BY SPECIFIC_SCHEMA, SPECIFIC_NAME;

    END IF;

    return $ret;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Groups_Members_Contains
(
    $GROUP_ID          INT,
    $USER              INT
)
RETURNS BOOL
READS SQL DATA
BEGIN

return EXISTS( SELECT * FROM base_groups_members WHERE GROUP_ID=$GROUP_ID AND USER=$USER );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Check_Password
(
  $USER                             INT(11),
  $Password                        CHAR(99)
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN

DECLARE $valid BOOLEAN DEFAULT FALSE;
DECLARE $email TEXT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT email INTO $email FROM base_users WHERE USER=$USER;

    SET $valid = users_verify_credentials( $email, $Password );

END IF;

return $valid;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Exists( $Email CHAR(99) )
RETURNS BOOLEAN
READS SQL DATA
BEGIN

DECLARE $exists BOOLEAN DEFAULT FALSE;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    return Exists( SELECT email FROM base_users WHERE email=$Email );

END IF;

return $exists;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Get_Field
(
$USER                    INT(11),
$field                  CHAR(99)
)
RETURNS TEXT
READS SQL DATA
BEGIN

DECLARE $value TEXT DEFAULT '';

CASE $field
WHEN 'type' THEN SELECT type INTO $value FROM base_users_uids WHERE USER=$USER;
END CASE;

return $value;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Send_Resets_Exists
(
  $token      CHAR(64)
)
RETURNS BOOL
READS SQL DATA
BEGIN

DECLARE $exists BOOLEAN DEFAULT FALSE;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

  SET $exists = EXISTS( SELECT * FROM base_users_send_resets WHERE token=$token );

END IF;

return $exists;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Send_Resets_Get_User
(
  $token      CHAR(64)
)
RETURNS INT
READS SQL DATA
BEGIN

    DECLARE $USER  INT  DEFAULT 0;

    SELECT   USER
    INTO    $USER
    FROM     base_users_send_resets
    WHERE    token=$token
    ORDER BY USER
    LIMIT    1;

    return $USER;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Verify_Credentials
(
  $Email              CHAR(99),
  $Password           CHAR(99)
)
RETURNS BOOL
READS SQL DATA
BEGIN

DECLARE $ret    BOOL;
DECLARE $salt   TEXT;
DECLARE $phash1 TEXT;
DECLARE $phash2 TEXT;

SET $ret = False;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    IF EXISTS( SELECT * FROM base_users WHERE email=$Email ) THEN

        SELECT user_salt     INTO $salt   FROM base_users WHERE email=$Email;
        SELECT password_hash INTO $phash1 FROM base_users WHERE email=$Email;

        SET $phash2 = ComputeHash( $salt, $Password );

        IF $phash1 = $phash2 THEN
            SET $ret = True;
        END IF;

    END IF;

END IF;

return $ret;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Sessions_Resolve_Sid
(
    $sid_at_ip  TEXT
)
RETURNS TEXT
READS SQL DATA
BEGIN

    DECLARE $sid  TEXT  DEFAULT '';
    DECLARE $Xid  TEXT  DEFAULT '';

    SET $Xid = SUBSTRING_INDEX( $sid_at_ip, '@', 1 );

    SELECT sid INTO $sid
    FROM   base_users_sessions
    WHERE
    (
        sid=$Xid AND ('' = csrf OR IsLocalCaller())
    )
    OR
    (
        (SUBSTRING( sid, 1, 32 ) = SUBSTRING( $Xid, 1, 32 ))
        AND
        (
            (SUBSTRING( csrf, 1, 32 ) = SUBSTRING( $Xid, 33, 32 ))
            OR
            EXISTS
            (
                SELECT *
                FROM   base_web_connections
                WHERE  SUBSTRING( connection_csrf_token, 1, 32 ) = SUBSTRING( $Xid, 33, 32 )
                AND    NOW() < connection_csrf_expiry
            )
        )
    );

    return $sid;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Files_Exists_By_Kind
(
  $Sid                             CHAR(64),
  $USER                             INT(11),
  $kind                            CHAR(30)
)
RETURNS BOOL
READS SQL DATA
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF $USER = @USER OR "ADMIN" = @idtype THEN

        return EXISTS( SELECT * FROM base_files WHERE USER=$USER AND kind=$kind );

    ELSE

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION';

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION LAST_INSERT_GUID
(
    $text TEXT
)
RETURNS CHAR(36)
NO SQL
BEGIN

return @LAST_INSERT_GUID;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION DistanceBetween
(
  $lat1  FLOAT,
  $lon1  FLOAT,
  $lat2  FLOAT,
  $lon2  FLOAT
)
RETURNS FLOAT
DETERMINISTIC
BEGIN

DECLARE $radius_earth_km INT DEFAULT 6371;

DECLARE $distance FLOAT;
DECLARE $sin1     FLOAT;
DECLARE $sin2     FLOAT;
DECLARE $cos1     FLOAT;
DECLARE $cos2     FLOAT;
DECLARE $power1   FLOAT;
DECLARE $power2   FLOAT;

SET $sin1 = SIN( ($lat1 - $lat2) * pi()/180/2);
SET $sin2 = SIN( ($lon1 - $lon2) * pi()/180/2);

SET $cos1 = COS( $lat1 * pi()/180);
SET $cos2 = COS( $lat2 * pi()/180);

SET $power1 = POWER( $sin1, 2 );
SET $power2 = POWER( $sin2, 2 );

SET $distance = $radius_earth_km * 2 * ASIN( SQRT( $power1 + $cos1 * $cos2 * $power2 ) );

return $distance;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION MetresBetween
(
  $lat1  FLOAT,
  $lon1  FLOAT,
  $lat2  FLOAT,
  $lon2  FLOAT
)
RETURNS INT
DETERMINISTIC
BEGIN

return CEIL( KilometresBetween( $lat1, $lon1, $lat2, $lon2 ) * 1000 );

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION KilometresBetween
(
  $lat1  FLOAT,
  $lon1  FLOAT,
  $lat2  FLOAT,
  $lon2  FLOAT
)
RETURNS FLOAT
DETERMINISTIC
BEGIN

return DistanceBetween( $lat1, $lon1, $lat2, $lon2 );

END
//
DELIMITER ;
CREATE TABLE base
(
    BASE_ID                  INT       AUTO_INCREMENT,
    base_url                 TEXT,
    base_created             DATETIME  DEFAULT  0,

    PRIMARY KEY( BASE_ID )
);
CREATE TABLE base_apikeys
(
    USER_OWNER               INT       DEFAULT      0,
    APIKEY_ID                INT       AUTO_INCREMENT,
    created                  DATETIME  DEFAULT      0,
    apikey                   CHAR(64)  DEFAULT     '',
    apikey_type              CHAR(30)  DEFAULT 'USER',
    ip_address               TEXT,

	ORG_ID                   INT       DEFAULT      0,
    PROJECT_ID               INT       DEFAULT      0,

    PRIMARY KEY(APIKEY_ID)
);
CREATE TABLE base_preregistrations
(
    name                           CHAR(99),
    email                          CHAR(99),
    mobile                         CHAR(20),
    info                           TEXT,
    TOKEN_ID                       INT,
    verified                       BOOL,
    created                        DATETIME,
    sent                           DATETIME,

    PRIMARY KEY (email)
);
CREATE TABLE base_groups
(
    GROUP_ID                       INT       AUTO_INCREMENT,
    GROUP_OWNER                    INT       NOT NULL,
    group_created                  DATETIME  NOT NULL,
    group_name                     CHAR(99)  NOT NULL,
    group_code                     CHAR(50)  NOT NULL,

    PRIMARY KEY (GROUP_ID)
);
CREATE TABLE base_groups_members
(
    GROUP_ID                       INT,
    USER                           INT,
    group_admin                    BOOL,

    PRIMARY KEY (GROUP_ID,USER)
);
CREATE TABLE base_templates
(
    TEMPLATE_ID       INT       AUTO_INCREMENT,
    template_created  DATETIME  NOT NULL,
    template_name     CHAR(50)  NOT NULL,
    template_txt64    TEXT,
    template_htm64    TEXT,
    #USER              INT       DEFAULT  0,
    #GROUP             INT       DEFAULT  0,

    PRIMARY KEY (TEMPLATE_ID)
);
CREATE TABLE base_users
(
    USER                           INT        NOT NULL,

    email                          CHAR(99)   NOT NULL,
    email_provisional              CHAR(99)   NOT NULL DEFAULT '',
    mobile                         CHAR(30)   NOT NULL DEFAULT 0,
    mobile_provisional             CHAR(30)   NOT NULL DEFAULT 0,

    created                        DATETIME   NOT NULL,
    last_login                     DATETIME   NOT NULL DEFAULT 0,
    invalid_logins                 INT        NOT NULL DEFAULT 0,

    user_salt                      CHAR(64)   NOT NULL,
    user_hash                      CHAR(64)   NOT NULL,
    password_hash                  CHAR(64)   NOT NULL,
    user_status                    CHAR(20)   NOT NULL,
    send_confirmation              BOOL       NOT NULL DEFAULT 0,
    sent                           BOOL       NOT NULL DEFAULT 0,
    confirmation_sent              DATETIME   NOT NULL DEFAULT 0,
    confirmed                      DATETIME   NOT NULL DEFAULT 0,
    user_deleted                   DATETIME   NOT NULL DEFAULT 0,
    DELETED_BY                     INT        NOT NULL DEFAULT 0,

    given_name                     CHAR(50)   NOT NULL,
    family_name                    CHAR(50)   NOT NULL,

    visits                         INT        NOT NULL DEFAULT 1,
    ts_users                       TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (email), UNIQUE KEY (USER)
);
CREATE TABLE base_users_alternate_emails
(
    USER                           INT       NOT NULL,
    TOKEN_ID                       INT       NOT NULL,
    email                          CHAR(99)  NOT NULL,
    email_verified                 BOOL      NOT NULL DEFAULT  0,

    PRIMARY KEY (USER,email)
);
CREATE TABLE base_users_device_logins
(
    USER                      INT       NOT NULL,
    USER_DEVICE_LOGIN_ID      INT       AUTO_INCREMENT,
    user_device_login_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_device_login_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    user_device_login_deleted TIMESTAMP DEFAULT 0,
    user_device_login_guid    CHAR(36)  NOT NULL,
    user_device_login_salt    TEXT      NOT NULL,
    user_device_login_hash    TEXT      NOT NULL,

    PRIMARY KEY(USER_DEVICE_LOGIN_ID)
)
COMMENT 'Authorised=ADMIN',
COMMENT 'Filter=USER_DEVICE_LOGIN_ID',
COMMENT 'OrderBy=USER_DEVICE_LOGIN_ID',
COMMENT 'Prefix=User_Device_Login_',
COMMENT 'Save=',
COMMENT 'Security=INVOKER';
CREATE TABLE base_users_mobiles
(
    USER                           INT       NOT NULL,
    user_mobile                    CHAR(20)  NOT NULL,
    user_mobile_device_id          CHAR(255) DEFAULT '',
    user_mobile_salt               CHAR(64)  DEFAULT '',
    user_mobile_hash               CHAR(64)  DEFAULT '',

    PRIMARY KEY (USER, user_mobile)
);
CREATE TABLE base_users_invalid
(
    email                          CHAR(99)   NOT NULL,
    invalid_created                TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
    invalid_logins                 INT        NOT NULL,

    invalid_sent                   DATETIME   DEFAULT 0,          

    PRIMARY KEY (email)
);
CREATE TABLE base_users_mobiles_enrolments
(
    USER                           INT       NOT NULL,
    user_mobile                    CHAR(20)  NOT NULL,
    user_mobile_device_id          CHAR(255) NOT NULL,
    sms_code                       CHAR(20)  NOT NULL,
    sms_code_created               DATETIME  DEFAULT 0,
    sms_code_sent                  DATETIME  DEFAULT 0,
    sms_code_verified              DATETIME  DEFAULT 0,

    PRIMARY KEY (USER, user_mobile, user_mobile_device_id)
);
CREATE TABLE base_users_sessions
(
    sid                            CHAR(64)   NOT NULL,
    csrf                           CHAR(64)   NOT NULL,
    AUTH_USER                      INT        NOT NULL,
    email                          CHAR(99)   NOT NULL,
    group_code                     CHAR(50)   NOT NULL,
    created                        DATETIME   NOT NULL,
    updated                        DATETIME   NOT NULL,
    expiry                         INT(64)    NOT NULL,

    PRIMARY KEY (sid)
);
CREATE TABLE base_users_sessions_log
(
    sid                            CHAR(64)   NOT NULL,
    AUTH_USER                      INT        NOT NULL,
    email                          CHAR(99)   NOT NULL,
    group_code                     CHAR(50)   NOT NULL,
    created                        DATETIME   NOT NULL,
    updated                        DATETIME   NOT NULL,
    expiry                         INT(64)    NOT NULL,

    PRIMARY KEY (sid)
);
CREATE TABLE base_users_termination_schedule
(
    USER                           INT       NOT NULL,
    mark                           DATETIME  NOT NULL,
    time_of_termination            DATETIME  NOT NULL,

    PRIMARY KEY (USER)
);
CREATE TABLE base_users_tokens
(
    TOKEN_ID                       INT       AUTO_INCREMENT,
    USER                           INT       NOT NULL,
    token_created                  DATETIME  NOT NULL,
    token_expiry_days              INT       DEFAULT 0,
    token_expiry                   DATETIME  DEFAULT 0,
    token_type                     CHAR(50)  NOT NULL,
    token                          CHAR(64)  NOT NULL,
    token_sent                     DATETIME  DEFAULT 0,
    token_used                     DATETIME  DEFAULT 0,

    PRIMARY KEY (TOKEN_ID)
);
CREATE TABLE base_users_uids
(
    USER                           INT       NOT NULL AUTO_INCREMENT,
    type                           CHAR(50)  NOT NULL DEFAULT '',

    PRIMARY KEY (USER)
);
CREATE TABLE base_users_requested_invites
(
REQUEST                             INT(11)  AUTO_INCREMENT,
email                           VARCHAR(99)  NOT NULL DEFAULT '',
time_of_request                DATETIME,
invite_sent                     BOOLEAN,

PRIMARY KEY (REQUEST)
);
CREATE TABLE base_users_activations (

USER                                INT(11)  NOT NULL,
timestamp                     TIMESTAMP      NOT NULL,
token                           VARCHAR(64)  NOT NULL,

PRIMARY KEY (USER)
);
CREATE TABLE base_users_send_resets
(
USER                                INT(11)  NOT NULL,
timestamp                     TIMESTAMP      NOT NULL,
token                           VARCHAR(64)  NOT NULL,
sent                          TIMESTAMP      NOT NULL,

PRIMARY KEY (USER)
);
CREATE TABLE base_users_deleted
(
USER         INT(11),
DELETED_USER INT(11)
);
CREATE TABLE base_exceptions
(
    EXCEPTION_ID              INT       AUTO_INCREMENT,
    exception_created         DATETIME  DEFAULT 0,
    exception_procedure_name  TEXT      DEFAULT '',
    exception_message         TEXT      DEFAULT '',

    PRIMARY KEY (EXCEPTION_ID)
);
CREATE TABLE base_files
(
    FILE                           INT        NOT NULL AUTO_INCREMENT,
    USER                           INT        NOT NULL,
    version                        DATETIME   NOT NULL,
    kind                           CHAR(30)   NOT NULL,

    original_filename              CHAR(255)  NOT NULL,
    filename                       CHAR(255)  NOT NULL,
    filetype                       CHAR(99)   NOT NULL,
    filesize                       CHAR(45)   NOT NULL,
    fileextension                  CHAR(10)   NOT NULL,
    salt                           INT(4)     NOT NULL,
    token                          CHAR(64)   NOT NULL,
    base64                         LONGBLOB   NOT NULL,

    PRIMARY KEY (FILE)
);
CREATE TABLE base_guids
(
    GUID_ID                        INT       NOT NULL,
    guid                           CHAR(36)  NOT NULL,
    guid_created                   DATETIME  NOT NULL,
    guid_type                      CHAR(50)  NOT NULL,
    REF_ID                         INT       NOT NULL,

    PRIMARY KEY (GUID_ID), UNIQUE KEY (guid)
);
CREATE TABLE base_logs
(
  LOG_ID                               INT(11) AUTO_INCREMENT,
  CALL_ID                              INT(11) NOT NULL,
  sessionid                           CHAR(64) NOT NULL,
  logged                              DATETIME NOT NULL,
  level                               CHAR(20) DEFAULT '',
  depth                                    INT DEFAULT  0,
  source                                  TEXT,
  message                                 TEXT,

  PRIMARY KEY (LOG_ID)
);
CREATE TABLE base_organisations
(
    ORG_ID                            INT       AUTO_INCREMENT,
    org_created                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    org_ts                            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    org_deleted                       DATETIME  DEFAULT  0,

    org_name                          TEXT      DEFAULT '',

    PRIMARY KEY (ORG_ID)
)
COMMENT 'Authorised=USER',
COMMENT 'Filter=ORG_ID;org_name',
COMMENT 'Save=org_name'
COMMENT 'OrderBy=org_name';
CREATE TABLE base_organisations_users
(
    ORG_ID                            INT       NOT NULL,
    ORG_USER_ID                       INT       NOT NULL,

    org_user_created                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    org_user_ts                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    org_user_deleted                  TIMESTAMP DEFAULT 0,

    org_user_role                     TEXT,

    PRIMARY KEY (ORG_ID,ORG_USER_ID)
);
CREATE TABLE base_places
(
    PLACE_ID                       INT       AUTO_INCREMENT,
    GROUP_ID                       INT       DEFAULT  0,
    input                          TEXT,
    suggested_google_place_id      TEXT,

    CONFIRMED_PLACE_SUGGESTION_ID  INT       DEFAULT  0,
    floor                          CHAR(10)  DEFAULT '',
    street_number                  CHAR(10)  DEFAULT '',
    street                         CHAR(99)  DEFAULT '',
    suburb                         CHAR(99)  DEFAULT '',
    city                           CHAR(99)  DEFAULT '',
    state                          CHAR(99)  DEFAULT '',
    country                        CHAR(99)  DEFAULT '',
    postal_code                    CHAR(10)  DEFAULT '',

    latitude                       DECIMAL(10,7)  DEFAULT 0.0,
    longitude                      DECIMAL(10,7)  DEFAULT 0.0,

    place_created                  DATETIME  DEFAULT  0,
    place_processed                DATETIME  DEFAULT  0,
    place_geocoded                 DATETIME  DEFAULT  0,
    place_confirmed                DATETIME  DEFAULT  0,
    place_error                    TEXT,

    PRIMARY KEY (PLACE_ID)
);
CREATE TABLE base_places_routes
(
    ROUTE_ID                         INT       AUTO_INCREMENT,
    GROUP_ID                         INT       DEFAULT      0,
    PLACE_OGN_ID                     INT       DEFAULT      0,
    PLACE_DST_ID                     INT       DEFAULT      0,
    route_created                    DATETIME  DEFAULT      0,
    route_processed                  DATETIME  DEFAULT      0,
    route_distance_metres            INT       DEFAULT      0,
    route_duration_seconds           INT       DEFAULT      0,
    route_shortest_distance_metres   INT       DEFAULT      0,
    route_shortest_duration_seconds  INT       DEFAULT      0,

    PRIMARY KEY (ROUTE_ID)
);
CREATE TABLE base_places_suggestions
(
    PLACE_SUGGESTION_ID            INT      AUTO_INCREMENT,
    PLACE_ID                       INT      NOT NULL,
    GROUP_ID                       INT      DEFAULT  0,

    google_place_id                TEXT,
    description                    TEXT,
    main_text                      TEXT,
    secondary_text                 TEXT,
    types                          TEXT,

    suggestion_type                ENUM( '', 'GEOCODE', 'AUTOCORRECT'), 
    suggestion_created             DATETIME DEFAULT 0,

    suggestion_floor               CHAR(20)  DEFAULT '',
    suggestion_street_number       CHAR(10)  DEFAULT '',
    suggestion_street              CHAR(99)  DEFAULT '',
    suggestion_suburb              CHAR(99)  DEFAULT '',
    suggestion_city                CHAR(99)  DEFAULT '',
    suggestion_state               CHAR(99)  DEFAULT '',
    suggestion_country             CHAR(99)  DEFAULT '',
    suggestion_postal_code         CHAR(10)  DEFAULT '',

    suggestion_latitude            DECIMAL(10,7)  DEFAULT 0.0,
    suggestion_longitude           DECIMAL(10,7)  DEFAULT 0.0,

    PRIMARY KEY (PLACE_SUGGESTION_ID)
);
CREATE TABLE base_projects
(
    USER          INT       NOT NULL,
    ORG_ID        INT       NOT NULL,
    GROUP_ID      INT       NOT NULL,
    PROJECT_ID    INT       AUTO_INCREMENT,

    project_guid  CHAR(36)  DEFAULT     '',
    project_name  TEXT,
    project_code  CHAR(50)  DEFAULT     '',

    PRIMARY KEY (PROJECT_ID)
);
CREATE TABLE base_projects_users
(
    USER               INT       NOT NULL,
    ORG_ID             INT       NOT NULL,
    GROUP_ID           INT       NOT NULL,
    PROJECT_ID         INT       NOT NULL,
    PROJECT_USER_ID    INT       AUTO_INCREMENT,
    project_user_guid  CHAR(36)  DEFAULT     '',
    project_roles      TEXT, 

    PRIMARY KEY (PROJECT_USER_ID),
    UNIQUE KEY (USER,ORG_ID,GROUP_ID,PROJECT_ID)
);
CREATE TABLE base_messaging
(
    USER                       INT       NOT NULL,
    MESSAGE_ID                 INT       AUTO_INCREMENT,
    message_created            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message_ts                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    message_deleted            TIMESTAMP DEFAULT 0,
    message_guid               TEXT      DEFAULT '',
    message_type               TEXT      DEFAULT '',
    message_from               TEXT      DEFAULT '',
    message_to                 TEXT      DEFAULT '',
    message_cc                 TEXT      DEFAULT '',
    message_bcc                TEXT      DEFAULT '',
    message_reply_to           TEXT      DEFAULT '',
    message_subject            TEXT      DEFAULT '',
    message_tags               TEXT      DEFAULT '',
    message_content_txt64      LONGTEXT  DEFAULT '',
    message_content_htm64      LONGTEXT  DEFAULT '',
    message_send_at            DATETIME  DEFAULT  0,
    message_sent_at            DATETIME  DEFAULT  0,
    message_response_code      TEXT      DEFAULT '',
    message_last_send_at       DATETIME  DEFAULT  0,
    message_last_sent_at       DATETIME  DEFAULT  0,
    message_last_response_code TEXT      DEFAULT '',
    message_is_test            BOOL      DEFAULT  0,

    PRIMARY KEY(MESSAGE_ID)
)
COMMENT 'Authorised=ADMIN',
COMMENT 'Filter=MESSAGE_ID',
COMMENT 'OrderBy=message_created',
COMMENT 'Prefix=Message_',
COMMENT 'Save=message_send_at;message_sent_at;message_response_code;message_last_send_at;message_last_sent_at;message_last_response_code',
COMMENT 'Security=INVOKER';
CREATE TABLE base_web_connections
(
    CONNECTION_ID           INT       NOT NULL AUTO_INCREMENT,
    connection_server_name  CHAR(99)  NOT NULL,
    connection_ip_remote    CHAR(45)  NOT NULL,
    connection_csrf_expiry  DATETIME  NOT NULL,
    connection_csrf_token   CHAR(64)  NOT NULL,

    PRIMARY KEY (CONNECTION_ID),
    UNIQUE  KEY (connection_server_name,connection_ip_remote,connection_csrf_expiry)
);
CREATE VIEW view_base_users AS
    SELECT
        USER,
        email,
        email_provisional,
        created,
        last_login,
        invalid_logins,
        user_hash,
        user_status,
        send_confirmation,
        sent,
        confirmation_sent,
        confirmed,
        user_deleted,
        DELETED_BY,
        IFNULL( deleted_by_email, '' ) AS deleted_by_email,
        given_name,
        family_name,
        visits,
        ts_users,
        type

    FROM      base_users
    LEFT JOIN base_users_uids USING (USER)
    LEFT JOIN
    (
        SELECT
            USER AS DELETED_BY,
            email AS deleted_by_email
            FROM base_users

    ) AS S0 USING (DELETED_BY);
CREATE VIEW view_base_users_admin AS
    SELECT
        USER,
        email,
        email_provisional,
        created,
        last_login,
        user_hash,
        user_status,
        send_confirmation,
        sent,
        confirmation_sent,
        confirmed,
        user_deleted,
        DELETED_BY,
        IFNULL( deleted_by_email, '' ) AS deleted_by_email,
        given_name,
        family_name,
        visits,
        ts_users,
        type

    FROM      base_users
    LEFT JOIN base_users_uids USING (USER)
    LEFT JOIN
    (
        SELECT
            USER AS DELETED_BY,
            email AS deleted_by_email
            FROM base_users

    ) AS S0 USING (DELETED_BY);
CREATE VIEW view_base_users_summaries AS
    SELECT
        USER,
        given_name,
        family_name,
        email,
        type

  FROM      base_users
  LEFT JOIN base_users_uids USING (USER);
CREATE VIEW view_base_users_sessions AS
    SELECT
        sid,
        USER,
        email,
        sid AS sessionid,
        type AS idtype,
        given_name,
        family_name,
        user_hash

    FROM      base_users_sessions
    LEFT JOIN base_users      USING (email)
    LEFT JOIN base_users_uids USING (USER);
CREATE VIEW view_base_files AS
    SELECT
        FILE,
        version,
        kind,
        original_filename,
        filename,
        filetype,
        filesize,
        fileextension,
        salt,
        token

    FROM base_files;
CREATE VIEW view_base_files_tokens AS
    SELECT FILE, token FROM base_files;
CREATE VIEW view_base_places_suggestions_unconfirmed AS
    SELECT    *
    FROM      base_places
    LEFT JOIN base_places_suggestions USING (PLACE_ID,GROUP_ID)
    WHERE     CONFIRMED_PLACE_SUGGESTION_ID=0;
DELIMITER //
CREATE PROCEDURE Base_APIKeys
(
    $Sid CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF NOT( @USER ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_APIKeys';

ELSE

    SELECT * FROM base_apikeys WHERE USER_OWNER=@USER ORDER BY created;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_APIKeys_Create
(
    $Sid           CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $APIKEY_ID  INT       DEFAULT  0;
DECLARE $apikey     CHAR(36)  DEFAULT '';

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT( @USER ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_APIKeys_Create';

ELSE

    REPLACE INTO base_apikeys ( APIKEY_ID ) VALUES ( 0 );
    SET $APIKEY_ID = LAST_INSERT_ID();

    UPDATE base_apikeys
    SET
        USER_OWNER=@USER,
        apikey=GenerateSalt(),
        created=NOW()

    WHERE APIKEY_ID=$APIKEY_ID;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_APIKeys_Authorisation
(
    $apikey           CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid_Or_APIKEY( '', $apikey, @email, @USER, @idtype );

IF "" = @idtype THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_APIKeys_Authorisation';

ELSE

    SELECT
        @email  AS email,
        @USER   AS USER;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authorise_Sessionid_Or_APIKey
(
    $Sid          CHAR(64),
    $apikey_at_ip TEXT,
OUT $email        TEXT,
OUT $USER         INT,
OUT $idtype       TEXT
)
SQL SECURITY INVOKER
BEGIN

SET $email  = "";
SET $USER   =  0;
SET $idtype = "";

IF "" != $Sid THEN

    CALL Base_Users_Authorise_Sessionid( $Sid, $email, $USER, $idtype );

END IF;

IF 0 = $USER AND "" != $apikey_at_ip THEN

    BEGIN

        DECLARE $apikey     TEXT  DEFAULT '';
        DECLARE $ip_address TEXT  DEFAULT '';

        SET $apikey     = SUBSTRING_INDEX( $apikey_at_ip, '@',  1 ); # Extract apikey
        SET $ip_address = SUBSTRING_INDEX( $apikey_at_ip, '@', -1 ); # Extract ip address

        SELECT
            email,
            USER_OWNER,
            type
        INTO
            $email,
            $USER,
            $idtype
        FROM      base_apikeys
        LEFT JOIN view_base_users ON (USER_OWNER=USER)
        WHERE     apikey=$apikey
        AND      (ISNULL(ip_address) OR ip_address = $ip_address);

    END;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authorise_Sessionid_And_APIKey
(
    $Sid          CHAR(64),
    $apikey_at_ip TEXT,
OUT $email        TEXT,
OUT $USER         INT,
OUT $idtype       TEXT
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $USER_OWNER  INT   DEFAULT  0;
    DECLARE $apikey      TEXT  DEFAULT '';
    DECLARE $ip_address  TEXT  DEFAULT '';

    SET $email  = "";
    SET $USER   =  0;
    SET $idtype = "";

    SET $apikey     = SUBSTRING_INDEX( $apikey_at_ip, '@',  1 ); # Extract apikey
    SET $ip_address = SUBSTRING_INDEX( $apikey_at_ip, '@', -1 ); # Extract ip address

    SELECT    USER_OWNER
    INTO     $USER_OWNER
    FROM      base_apikeys
    WHERE     apikey=$apikey
    AND      (ISNULL(ip_address) OR ip_address = $ip_address);

    IF $USER_OWNER THEN

        CALL Base_Users_Authorise_Sessionid( $Sid, $email, $USER, $idtype );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authorise_Sessionid_Or_APIKey_For_Org
(
    $Sid            CHAR(64),
    $apikey         CHAR(64),
INOUT
    $ORG_ID         INT,
OUT $email          TEXT,
OUT $USER           INT,
OUT $idtype         TEXT,
OUT $org_user_role  TEXT
)
SQL SECURITY INVOKER
BEGIN

    SET $org_user_role = "";

    CALL Base_Users_Authorise_Sessionid_Or_Apikey( $Sid, $apikey, $email, $USER, $idtype );

    IF "ADMIN" = $idtype THEN

        SET $org_user_role = "QUERY.REPLACE.SAVE.DELETE";

    ELSE

        SELECT org_user_role INTO $org_user_role
        FROM   base_organisations_users
        WHERE  ORG_ID      = $ORG_ID
        AND    ORG_USER_ID = $USER;

        IF "" = $org_user_role THEN
            SET $ORG_ID = 0;
        END IF;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authorise_APIKey
(
    $apikey_at_ip TEXT,
OUT $email        TEXT,
OUT $idtype       TEXT,
OUT $apikey_type  TEXT,
OUT $USER         INT,
OUT $ORG_ID       INT,
OUT $PROJECT_ID   INT
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $apikey     TEXT  DEFAULT '';
    DECLARE $ip_address TEXT  DEFAULT '';

    SET $email       = "";
    SET $idtype      = "";
    SET $apikey_type = "";
    SET $USER        =  0;
    SET $ORG_ID      =  0;
    SET $PROJECT_ID  =  0;

    SET $apikey     = SUBSTRING_INDEX( $apikey_at_ip, '@',  1 ); # Extract apikey
    SET $ip_address = SUBSTRING_INDEX( $apikey_at_ip, '@', -1 ); # Extract ip address

    SELECT
        email,
        type,
        apikey_type,
        USER_OWNER,
        ORG_ID,
        PROJECT_ID

    INTO
        $email,
        $idtype,
        $apikey_type,
        $USER,
        $ORG_ID,
        $PROJECT_ID

    FROM      base_apikeys
    LEFT JOIN view_base_users ON (USER_OWNER=USER)
    WHERE     apikey=$apikey
    AND      (ISNULL(ip_address) OR ip_address = $ip_address);

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Exceptions_Log
(
    $exception_procedure_name  TEXT,
    $exception_message         LONGTEXT
)
BEGIN

    INSERT INTO base_exceptions
    (  EXCEPTION_ID,  exception_created,  exception_procedure_name,  exception_message )
    VALUES
    (             0,              NOW(), $exception_procedure_name, $exception_message );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Preregistrations_Replace
(
  $name                    CHAR(99),
  $email                   CHAR(99),
  $mobile                  CHAR(20),
  $info                        TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $token CHAR(64);

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SET $token = GenerateSalt();

    REPLACE INTO base_preregistrations
        (  name,  email,  mobile,  info,  TOKEN_ID,  verified,  created,  sent )
    VALUES
        ( $name, $email, $mobile, $info,       '0',       '0',    NOW(),  sent );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Preregistrations_Confirm
(
  $token                        TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    UPDATE base_preregistrations SET confirmed=NOW() WHERE token=$token;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Preregistrations_Unsent
(
    $Sid CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    IF 'LOCAL' = $Sid AND IsLocalCaller() THEN

        SELECT *, email AS TID FROM base_preregistrations WHERE confirmation_sent=0;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Preregistrations_Sent
(
    $Sid                       TEXT,
    $TID                       CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    IF 'LOCAL' = $Sid AND IsLocalCaller() THEN

      UPDATE base_preregistrations SET confirmation_sent=NOW() WHERE email=$TID;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Admin
(
    $sid  CHAR(64),
    $USER  INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF NOT( 'ADMIN' = @idtype ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Admin';

    ELSEIF $USER THEN

        SELECT * FROM view_base_users_admin WHERE USER=$USER;

    ELSE

        SELECT * FROM view_base_users_admin ORDER BY given_name, family_name, email;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Admin_Update
(
    $Sid          CHAR(64),
    $USER         INT,
    $given_name   TEXT,
    $family_name  TEXT,
    $email        TEXT,
    $password     TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT( 'ADMIN' = @idtype ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Admin_Update';

    ELSE

        UPDATE base_users
        SET
            given_name  = $given_name,
            family_name = $family_name,
            email       = $email

        WHERE USER = $USER;

        IF "" != $password THEN
            CALL base_users_reset_password( $Sid, $USER, $password );
        END IF;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Create_Admin
(
  $password                      CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

DECLARE $send_email INT DEFAULT 0;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT IsRootCaller() THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Create_Admin';

ELSE

    CALL Base_Users_Create_Quietly( 'admin', $password, 'Admin', 'Account', 'ADMIN', $send_email );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Admin_Reset_Password
(
  $email        CHAR(99),
  $new_password CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $USER  INT  DEFAULT 0;

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT IsRootCaller() THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Admin_Reset_Password';

    ELSE

        SELECT  USER
        INTO   $USER
        FROM    base_users
        WHERE   email = $email;

        CALL base_users_set_password( $USER, $new_password );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE base_users_reset_password
(
  $Sid          CHAR(64),
  $USER         INT(11),
  $new_password CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF "ADMIN" = @idtype THEN

        CALL base_users_set_password( $USER, $new_password );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve_All
(
$Sid                           CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF "ADMIN" = @idtype THEN

        SELECT * FROM view_base_users ORDER BY USER DESC;

    ELSE

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION';

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Admin_Tables
()
SQL SECURITY INVOKER
BEGIN

    DECLARE $current_db TEXT DEFAULT '';

    SET $current_db = DATABASE();

    SELECT   TABLE_SCHEMA, TABLE_NAME, TABLE_ROWS, DATA_LENGTH, FLOOR(DATA_LENGTH / 1000) As KB, FLOOR(DATA_LENGTH / 1000000) As MB
    FROM     information_schema.TABLES
    WHERE    TABLE_SCHEMA = $current_db
    AND      NOT ISNULL(TABLE_ROWS)
    ORDER BY DATA_LENGTH;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authorise_SessionID
(
      $Xid          CHAR(64),
  OUT $Email        CHAR(99),
  OUT $USER          INT(11),
  OUT $IDType    VARCHAR(20)
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $sid CHAR(64) DEFAULT 0;

    SET $sid    = Base_Users_Sessions_Resolve_Sid( $Xid );
    SET $Email  = "";
    SET $USER   = "";
    SET $IDType = "";

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF Base_Users_Sessions_Verify( $sid ) THEN

        CALL Base_Users_Sessions_Extend_Expiry( $sid );

        SELECT AUTH_USER INTO $USER   FROM base_users_sessions WHERE sid  = $sid;
        SELECT email     INTO $Email  FROM base_users          WHERE USER = $USER;
        SELECT type      INTO $IDType FROM base_users_uids     WHERE USER = $USER;

        IF $Email IS NULL THEN

            SET $Email = "";

        END IF;

        IF $IDType IS NULL THEN

            SET $IDType = "";

        END IF;

    ELSE

        CALL Base_Users_Sessions_Terminate( $sid );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Current
(
    $Sid CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF NOT( @idtype LIKE '%USER%' ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Current';

    ELSE

        SELECT
            USER,
            email,
            given_name,
            family_name

        FROM base_users WHERE USER=@USER;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Update
(
    $Sid                      CHAR(64),
    $USER                     INT(11),
    $email                    CHAR(99),
    $given_name               CHAR(50),
    $family_name              CHAR(50)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $E CHAR(99) DEFAULT NULL;
    DECLARE $U  INT(11) DEFAULT NULL;
    DECLARE $I CHAR(99) DEFAULT NULL;

    DECLARE $old_email         CHAR(99);
    DECLARE $email_provisional CHAR(99);

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT( $USER = @USER OR @idtype LIKE '%ADMIN%' ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Update';

    ELSE

        SELECT email             INTO $old_email         FROM base_users WHERE USER=$USER;
        SELECT email_provisional INTO $email_provisional FROM base_users WHERE USER=$USER;

        IF $email != $old_email THEN
            SET $email_provisional = $email;
        END IF;

        UPDATE base_users
        SET
            email_provisional = $email_provisional,
            given_name        = $given_name,
            family_name       = $family_name

        WHERE USER=$USER;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Create
(
$Email                     CHAR(99),
$Password                  CHAR(99),
$Given_name                CHAR(50),
$Family_name               CHAR(50),
$Type                      CHAR(20)
)
SQL SECURITY INVOKER
BEGIN

CALL Base_Users_Create_Quietly( $Email, $Password, $Given_name, $Family_name, $Type, TRUE );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Create_Quietly
(
$Email                     CHAR(99),
$Password                  CHAR(99),
$Given_name                CHAR(50),
$Family_name               CHAR(50),
$Type                      CHAR(20),
$Send                      BOOL
)
SQL SECURITY INVOKER
BEGIN

DECLARE $USER   INT;
DECLARE $salt   TEXT;
DECLARE $uhash  TEXT;
DECLARE $phash  TEXT;

SET $Password = TRIM( $Password );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF "" = $Email OR EXISTS( SELECT * FROM base_users WHERE email=$Email ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_EMAIL';

ELSEIF NOT "" = $Password AND "WEAK" = CalculatePasswordStrength( $Password ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WEAK_PASSWORD';

ELSE

    IF ! Base_Users_Exists( $Email ) THEN

        INSERT INTO base_users_uids (type) VALUES ( $Type );
        SET $USER  = LAST_INSERT_ID();
        SET $salt  = GenerateSalt();
        SET $uhash = ComputeHash( $salt, $Email    );
        SET $phash = ComputeHash( $salt, $Password );

        IF "" = $Password THEN
            SET $phash = "";
        END IF;

        INSERT INTO base_users
            (  USER,  email, created,  user_salt, user_hash, password_hash, send_confirmation,   user_status,  given_name,  family_name )
        VALUES
            ( $USER, $Email,   NOW(),      $salt,    $uhash,        $phash,             $Send, "UNCONFIRMED", $Given_name, $Family_name );

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Save
(
$USER   INT,
$name   TEXT,
$value  TEXT
)
SQL SECURITY INVOKER
BEGIN

    CASE $name
    WHEN 'mobile'             THEN UPDATE base_users SET mobile             = $value WHERE USER = $USER AND user_deleted = 0;
    WHEN 'mobile_provisional' THEN UPDATE base_users SET mobile_provisional = $value WHERE USER = $USER AND user_deleted = 0;
    ELSE

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CASE_OPTION IN Base_Users_Create';

    END CASE;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE base_users_Set_Password
(
  $USER         INT(11),
  $new_password CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $email TEXT;
    DECLARE $salt  TEXT;
    DECLARE $uhash TEXT;
    DECLARE $phash TEXT;

    SET $new_password = TRIM( $new_password );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF "WEAK" = CalculatePasswordStrength( $new_password ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WEAK_PASSWORD';

    ELSE

        SELECT email INTO $email FROM base_users WHERE USER=$USER;

        SET $salt  = GenerateSalt();
        SET $uhash = ComputeHash( $salt, $email        );
        SET $phash = ComputeHash( $salt, $new_password );

        IF "" = $new_password THEN
            SET $phash = "";
        END IF;

        UPDATE base_users
        SET
            user_salt=$salt,
            user_hash=$uhash,
            password_hash=$phash,
            invalid_logins=0

        WHERE USER=$USER;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Reactivate
(
  $email  TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    UPDATE base_users
    SET
        send_confirmation = 1,
        sent              = 0

    WHERE email = $email;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Activation_Sent
(
$Email              CHAR(99),
$Password           CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    IF Users_Vefify_Credentials( $Email, $Password ) THEN

        UPDATE base_users SET sent=1 WHERE email=$Email;

    ELSE

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION';

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Resend_Activation
(
$email                     CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

DECLARE $USER INT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT USER INTO $USER FROM base_users WHERE email=$email;

    IF EXISTS( SELECT * FROM base_users_activations WHERE USER=$USER ) THEN

        UPDATE base_users SET sent=0 WHERE email=$email;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve_Unsent
()
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF IsRootCaller() THEN

    SELECT * FROM view_base_users WHERE sent=0;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve_Unsent_With_Names
()
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF IsRootCaller() THEN

    SELECT * FROM view_base_users WHERE sent=0 AND NOT given_name='' AND NOT family_name='';

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Update_Sent
(
  $Email              CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF IsRootCaller() THEN

    UPDATE base_users SET sent=1, confirmation_sent=NOW() WHERE email=$Email OR email_provisional=$Email;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users
(
$Sid                           CHAR(64),
$USER                           INT(11)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @E, @U, @I );

    IF 'LOCAL' = $Sid AND IsLocalCaller() AND $USER THEN

        SELECT * FROM base_users WHERE USER=$USER;

    ELSEIF 'LOCAL' = $Sid AND IsLocalCaller() THEN

        SELECT * FROM base_users;

    ELSEIF $USER = @U THEN

        SELECT * FROM base_users WHERE USER=$USER;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve
(
$Sid                           CHAR(64),
$USER                           INT(11)
)
SQL SECURITY INVOKER
BEGIN

DECLARE $E CHAR(99) DEFAULT NULL;
DECLARE $U  INT(11) DEFAULT NULL;
DECLARE $I CHAR(99) DEFAULT NULL;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, $E, $U, $I );

    IF $USER = $U THEN

        SELECT * FROM base_users WHERE USER=$USER;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve_Single
(
  $Sid                       CHAR(64),
  $USER                       INT(11)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF @USER = $USER THEN

      SELECT * FROM base_users WHERE USER=$USER LIMIT 1;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve_Signups
(
  $days INT(11)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF IsRootCaller() THEN

    SELECT email, sent, user_status, given_name, family_name, user_hash
    FROM base_users
    WHERE created > DATE_SUB( NOW(), INTERVAL $days DAY );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Update_Name
(
  $Sid                       CHAR(64),
  $USER                       INT(11),
  $given_name                CHAR(50),
  $family_name               CHAR(50)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF @USER = $USER THEN

      UPDATE base_users SET given_name=$given_name, family_name=$family_name WHERE USER=$USER;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Retrieve_By_User_Hash
(
  $sid                             CHAR(64),
  $user_hash                       CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF "" != @idtype THEN

        SELECT * FROM base_users WHERE user_hash=$user_hash;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Change_Password
(
  $Email       CHAR(99),
  $OldPassword CHAR(99),
  $NewPassword CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

DECLARE ret   BOOL;
DECLARE salt  TEXT;
DECLARE uhash TEXT;
DECLARE phash TEXT;

SET ret = False;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF "WEAK" = CalculatePasswordStrength( $Password ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WEAK_PASSWORD';

ELSE

    IF base_users_verify_credentials( $Email, $OldPassword ) THEN

        SET salt  = GenerateSalt();
        SET uhash = ComputeHash( salt, $Email    );
        SET phash = ComputeHash( salt, $NewPassword );

        UPDATE base_users
        SET user_salt=salt, user_hash=uhash, password_hash=phash
        WHERE email=$Email;

        SET ret = True;

    END IF;

    SELECT ret AS success;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE base_users_change_password_with_USER
(
  $USER         INT(11),
  $OldPassword CHAR(99),
  $NewPassword CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

DECLARE $email TEXT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT email INTO $email FROM base_users WHERE USER=$USER;

    IF "" != $email THEN

      CALL base_users_change_password( $email, $OldPassword, $NewPassword );

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Activations_Create
(
  $email                           CHAR(99)
)
BEGIN

    DECLARE $token TEXT;

    CALL Users_Activations_Create_Out( $email, $token );

    SELECT $token AS token;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Activations_Create_Out
(
    $email  CHAR(99),
OUT $token  TEXT
)
BEGIN

    DECLARE $USER  INT;

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        SET $token = GenerateSalt();

        SELECT USER INTO $USER FROM base_users WHERE email=$email OR email_provisional=$email;

        IF $USER THEN
            REPLACE INTO base_users_activations VALUES ( $USER, NOW(), $token );
        END IF;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Activations_Confirm_Account
(
  $token     CHAR(64),
  $password  TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $USER              INT;
    DECLARE $email             TEXT;
    DECLARE $email_provisional TEXT;

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        SELECT USER INTO $USER FROM base_users_activations WHERE token=$token;

        IF NOT $USER THEN

            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_TOKEN IN Base_Users_Activations_Confirm_Account';

        ELSE
      
            SELECT email,  email_provisional
            INTO  $email, $email_provisional
            FROM   base_users
            WHERE  USER = $USER;
        
            IF "" != $email_provisional THEN
                SET $email = $email_provisional;
            END IF;

            UPDATE base_users
            SET
                email             = $email,
                email_provisional = '',
                user_status='CONFIRMED'

            WHERE USER=$USER;

            IF NOT "" = $password THEN

                CALL base_users_set_password( $USER, $password );

            END IF;

            DELETE FROM base_users_activations WHERE token = $token;

        END IF;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Activations_Confirm_Account_And_Authenticate
(
  $token                           CHAR(64)
)
BEGIN

DECLARE $USER              INT;
DECLARE $email             TEXT;
DECLARE $email_provisional TEXT;
DECLARE $sessionid         TEXT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT USER INTO $USER FROM users_activations WHERE token=$token;

    SET $sessionid = "";

    IF 0 != $USER THEN
        SELECT email, email_provisional INTO $email, $email_provisional
        FROM users WHERE USER=$USER;
        
        IF "" != $email_provisional THEN
            SET $email = $email_provisional;
        END IF;

        UPDATE users SET email=$email, email_provisional='', user_status='CONFIRMED' WHERE USER=$USER;
        DELETE FROM users_activations WHERE token=$token;

        SET $sessionid = MD5( concat( $token, NOW() ) );
        REPLACE INTO users_sessions VALUES ( $sessionid, $email, NOW(), NOW(), UNIX_TIMESTAMP() + 1000 );
    END IF;

    SELECT $sessionid AS sessionid;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Alternate_Emails_Create
(
  $Sid                       CHAR(64),
  $USER                       INT(11),
  $email                  VARCHAR(99)
)
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

	IF @USER = $USER THEN

	  REPLACE INTO users_alternate_emails VALUES ( $USER, $email, GenerateSalt() );

	END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Alternate_Emails_Delete
(
  $Sid                       CHAR(64),
  $USER                       INT(11),
  $Email                  VARCHAR(99)
)
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

	IF @USER = $USER THEN
		DELETE FROM users_alternate_emails WHERE USER=$USER AND email=$Email;
	END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Alternate_Emails_Retrieve_By_USER
(
  $Sid                       CHAR(64),
  $USER                       INT(11)
)
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

	IF @USER = $USER THEN
		SELECT * FROM users_alternate_emails WHERE USER=$USER ORDER BY email;
	END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Delete
(
  $Sid  CHAR(64),
  $USER INT(11)
)
BEGIN

DECLARE $email TEXT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	IF "" != $Sid THEN
        CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );
        INSERT INTO users_deleted VALUES ( @USER, $USER );
	END IF;

	SELECT email INTO $email FROM users WHERE USER=$USER;

	DELETE FROM users_activations          WHERE USER=$USER;
	DELETE FROM users_alternate_emails     WHERE USER=$USER;
	DELETE FROM users_send_resets          WHERE USER=$USER;
	DELETE FROM users_sessions             WHERE email=$email;
	DELETE FROM users_uids                 WHERE USER=$USER;
	DELETE FROM users_termination_schedule WHERE USER=$USER;
	DELETE FROM users                      WHERE USER=$USER;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Mobiles_Replace
(
    $Sid                    CHAR(64),
    $USER                   INT,
    $user_mobile            CHAR(20)
)
SQL SECURITY DEFINER
BEGIN

SET $user_mobile = Internationalise_Mobile( $user_mobile );

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF FALSE THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Mobiles_Replace';

ELSE

    REPLACE INTO base_users_mobiles
    (  USER,  user_mobile,  user_mobile_device_id )
    VALUES
    ( $USER, $user_mobile,                     '' );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Mobiles_Enrolments_Create
(
    $user_mobile            CHAR(20),
    $user_mobile_device_id  CHAR(255)
)
SQL SECURITY DEFINER
BEGIN

DECLARE $USER      INT      DEFAULT  0;
DECLARE $sms_code  CHAR(4)  DEFAULT '';

SET $sms_code    = SUBSTRING( GenerateSalt(), 1, 4 );
SET $user_mobile = Internationalise_Mobile( $user_mobile );

SELECT USER INTO $USER FROM base_users_mobiles WHERE user_mobile = $user_mobile;

REPLACE INTO base_users_mobiles_enrolments
(  USER,  user_mobile,  user_mobile_device_id,  sms_code,  sms_code_created )
VALUES
( $USER, $user_mobile, $user_mobile_device_id, $sms_code,             NOW() );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Mobiles_Enrolments_Confirm
(
    $user_mobile            CHAR(20),
    $user_mobile_device_id  CHAR(255),
    $sms_code               CHAR(20)
)
SQL SECURITY DEFINER
BEGIN

DECLARE $USER      INT       DEFAULT  0;
DECLARE $verified  BOOL      DEFAULT  0;
DECLARE $salt      CHAR(64)  DEFAULT '';
DECLARE $token     CHAR(64)  DEFAULT '';

SET $user_mobile = Internationalise_Mobile( $user_mobile );

SELECT USER INTO $USER FROM base_users_mobiles WHERE user_mobile = $user_mobile;

SET $verified = EXISTS
(
    SELECT *
    FROM   base_users_mobiles_enrolments
    WHERE  USER                  = $USER
    AND    user_mobile           = $user_mobile
    AND    user_mobile_device_id = $user_mobile_device_id
    AND    sms_code              = $sms_code
    AND    sms_code_verified     = 0
);

IF NOT $verified THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Users_Mobiles_Enrolments_Confirm';

ELSE

    #
    #   Finalise enrolment
    #

    UPDATE base_users_mobiles_enrolments
    SET
        sms_code_verified = NOW()

    WHERE USER                  = $USER
    AND   user_mobile           = $user_mobile
    AND   user_mobile_device_id = $user_mobile_device_id;

    #
    #   Generate mobile authentication token
    #

    SET $salt  = GenerateSalt();
    SET $token = GenerateSalt();

    UPDATE base_users_mobiles
    SET
        user_mobile_device_id   = $user_mobile_device_id,
        user_mobile_salt        = $salt,
        user_mobile_hash        = ComputeHash( $salt, $token )

    WHERE USER                  = $USER
    AND   user_mobile           = $user_mobile;

    SELECT $token AS token;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Requested_Invites_Replace
(
  $email                         CHAR(99)
)
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	IF NOT EXISTS( SELECT * FROM users_requested_invites WHERE email=$email ) THEN
		REPLACE INTO users_requested_invites
			   (  REQUEST,  email, time_of_request, invite_sent )
		VALUES (        0, $email,           NOW(),           0 );
	END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Requested_Invites_Retrieve
(
  $sid                           CHAR(64)
)
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF "SID" = @idtype THEN
        IF NOT EXISTS( SELECT * FROM users_requested_invites WHERE email=@email ) THEN
            SELECT * FROM users_requested_invites ORDER BY time_of_request;
        END IF;
    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Send_Resets_Replace
(
  $email      CHAR(99)
)
BEGIN

DECLARE $USER  INT;
DECLARE $token TEXT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SET $token = GenerateSalt();

    SELECT   USER
    INTO    $USER
    FROM     base_users
    WHERE    email = $email
    AND      user_deleted = 0
    ORDER BY USER
    LIMIT    1;

    IF $USER THEN
      REPLACE INTO base_users_send_resets VALUES ( $USER, NOW(), $token, 0 );
    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Send_Resets_Replace_OTC
(
  $mobile     TEXT,
  $email      TEXT,
  $otc        TEXT
)
BEGIN

    DECLARE $USER   INT   DEFAULT  0;
    DECLARE $token  TEXT  DEFAULT '';

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        SELECT   USER
        INTO    $USER
        FROM     base_users
        WHERE    user_deleted = 0
        AND
        (
            (''    = $email AND email  = $mobile)
            OR
            (''    = $email AND mobile = $mobile)
            OR
            (email = $email AND mobile = $mobile)
        )
        ORDER BY USER
        LIMIT    1;

        IF IsLocalCaller() AND NOT $USER THEN

            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_USER';

        END IF;

        IF $USER THEN
            REPLACE INTO base_users_send_resets VALUES ( $USER, NOW(), $otc, 0 );

            CALL Base_Messaging_Create
            (
                $USER,
                'SMS',
                '0412669210',
                $mobile,
                '',
                '',
                '',
                '',
                'otc',
                TO_BASE64
                (
                    CONCAT_WS
                    (
                        " ",
                        "Minobs one-time-code",
                        $otc
                    )
                ),
                '',
                NOW()
            );

        END IF;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Send_Resets_Retrieve
()
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT * FROM base_users_send_resets LEFT JOIN users USING (USER) WHERE users_send_resets.sent=0;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Send_Resets_Sent
(
  $email  CHAR(99)
)
BEGIN

DECLARE $USER INT;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT USER INTO $USER FROM users_send_resets LEFT JOIN users USING (USER) WHERE email=$email LIMIT 1;

    UPDATE base_users_send_resets SET sent=NOW() WHERE USER=$USER;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Send_Resets_Reset_Password
(
  $token                           CHAR(64),
  $password                        CHAR(99)
)
BEGIN

DECLARE $USER  INT;
DECLARE $email TEXT;
DECLARE $salt  TEXT;
DECLARE $uhash TEXT;
DECLARE $phash TEXT;

SET $password = TRIM( $password );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF "WEAK" = CalculatePasswordStrength( $password ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WEAK_PASSWORD';

ELSE

    SELECT USER INTO $USER FROM base_users_send_resets WHERE token=$token;

    IF NOT $USER THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_TOKEN';

    ELSE

        SELECT email INTO $email FROM base_users WHERE USER=$USER;

        SET $salt  = GenerateSalt();
        SET $uhash = ComputeHash( $salt, $email );
        SET $phash = ComputeHash( $salt, $Password );

        IF $password = "" THEN
            SET $phash = "";
        END IF;

        UPDATE base_users
        SET user_salt=$salt, user_hash=$uhash, password_hash=$phash, invalid_logins=0
        WHERE USER=$USER;

        DELETE FROM base_users_send_resets WHERE token=$token;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Send_Resets_Reset_Password_OTC
(
  $token                           CHAR(64),
  $deviceid                        TEXT,
  $password                        TEXT
)
BEGIN

DECLARE $USER  INT;
DECLARE $email TEXT;
DECLARE $salt  TEXT;
DECLARE $uhash TEXT;
DECLARE $phash TEXT;

SET $deviceid = TRIM( $deviceid );
SET $password = TRIM( $password );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF "WEAK" = CalculatePasswordStrength( $password ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WEAK_PASSWORD';

ELSE

    SELECT USER INTO $USER FROM base_users_send_resets WHERE token=$token;

    IF NOT $USER THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_TOKEN';

    ELSE

        SELECT email INTO $email FROM base_users WHERE USER=$USER;

        SET $salt  = GenerateSalt();
        SET $uhash = ComputeHash( $salt, $email );
        SET $phash = ComputeHash( $salt, $Password );

        IF $password = "" THEN
            SET $phash = "";
        END IF;

        IF "" = $deviceid THEN

            UPDATE base_users
            SET user_salt=$salt, user_hash=$uhash, password_hash=$phash, invalid_logins=0
            WHERE USER=$USER;

        ELSE

            CALL Base_Users_Device_Logins_Replace
            (
                $USER,
                0,
                $deviceid,
                $salt,
                $phash
            );

        END IF;

        DELETE FROM base_users_send_resets WHERE token=$token;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Sessions_Replace
(
  $email                           CHAR(99),
  $password                        CHAR(99)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

SET @status    = "";
SET @sessionid = "";
SET @USER      = 0;
SET @idtype    = "";

CALL Base_Users_Sessions_Replace_Inout( $email, $password, @status, @sessionid, @USER, @idtype );

SELECT @status AS status, @sessionid AS sessionid, @USER AS USER, @idtype AS idtype;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Sessions_Replace
(
  $email                           CHAR(99),
  $password                        CHAR(99)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

SET @status    = "";
SET @sessionid = "";
SET @USER      = 0;
SET @idtype    = "";

CALL Base_Users_Sessions_Replace_Inout( $email, $password, @status, @sessionid, @USER, @idtype );

SELECT @status AS status, @sessionid AS sessionid, @USER AS USER, @idtype AS idtype;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authenticate
(
  $Sid CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $read_only BOOL;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    IF Base_Users_Sessions_Verify( $Sid ) THEN

      CALL Base_Users_Sessions_Extend_Expiry( $Sid );

      SELECT email, USER, given_name, family_name, type AS idtype, group_code, last_login, user_status, user_hash, $read_only AS read_only
      FROM base_users_sessions
      LEFT JOIN view_base_users USING (email) WHERE sid=$Sid;

    ELSE

      CALL Base_Users_Sessions_Terminate( $Sid );

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Users_Authenticate
(
  $Sid CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authenticate( $Sid );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Authorize_SessionID
(
      $Sid          CHAR(64),
  OUT $Email        CHAR(99),
  OUT $USER          INT(11),
  OUT $IDType    VARCHAR(20)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, $Email, $USER, $IDType );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Sessions
(
  $Sid                             CHAR(64),
  $USER                            CHAR(64),
  $user_hash                       CHAR(64),
  $order                           CHAR(99),
  $limit                            INT(11),
  $offset                           INT(11)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Sessions_Replace_Inout
(
      $email                         CHAR(99),
      $password                      CHAR(99),
INOUT $status                        CHAR(99),
INOUT $sessionid                     CHAR(64),
INOUT $USER                           INT(11),
INOUT $idtype                        CHAR(20)
)
SQL SECURITY INVOKER
BEGIN

    CALL Base_Users_Sessions_Replace_w_DeviceID_Inout
    (
        '',
        $email,
        $password,
        $status,
        $sessionid,
        $USER,
        $idtype
    );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Sessions_Replace_w_DeviceID_Inout
(
      $deviceid                      CHAR(99),
      $email                         CHAR(99),
      $password                      CHAR(99),
INOUT $status                        CHAR(99),
INOUT $sessionid                     CHAR(64),
INOUT $USER                           INT(11),
INOUT $idtype                        CHAR(20)
)
SQL SECURITY INVOKER
BEGIN

DECLARE $start          TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
DECLARE $authenticated  BOOL      DEFAULT  0;
DECLARE $salt           TEXT      DEFAULT '';
DECLARE $phash1         TEXT      DEFAULT '';
DECLARE $phash2         TEXT      DEFAULT '';
DECLARE $invalid        INT       DEFAULT  0;
DECLARE $group_code     TEXT      DEFAULT '';
DECLARE $csrf           TEXT      DEFAULT '';

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    #
    #   Housekeeping
    #

    DELETE FROM base_users_sessions WHERE expiry < UNIX_TIMESTAMP();

    IF ("" = $deviceid AND "" = $email) OR "" = $password THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CREDENTIALS';

    ELSE

        IF EXISTS( SELECT * FROM base_users_mobiles WHERE user_mobile_device_id=$email ) THEN

            SELECT USER             INTO $USER   FROM base_users_mobiles WHERE user_mobile_device_id = $email;
            SELECT user_mobile_salt INTO $salt   FROM base_users_mobiles WHERE user_mobile_device_id = $email;
            SELECT user_mobile_hash INTO $phash1 FROM base_users_mobiles WHERE user_mobile_device_id = $email;

        ELSEIF EXISTS( SELECT * FROM base_users_device_logins WHERE user_device_login_guid = $deviceid ) THEN

            SELECT USER                   INTO $USER   FROM base_users_device_logins WHERE user_device_login_guid = $deviceid ORDER BY user_device_login_created DESC LIMIT 1;
            SELECT user_device_login_salt INTO $salt   FROM base_users_device_logins WHERE user_device_login_guid = $deviceid ORDER BY user_device_login_created DESC LIMIT 1;
            SELECT user_device_login_hash INTO $phash1 FROM base_users_device_logins WHERE user_device_login_guid = $deviceid ORDER BY user_device_login_created DESC LIMIT 1;

        ELSE

            SELECT USER             INTO $USER       FROM base_users WHERE email=$email;
            SELECT user_salt        INTO $salt       FROM base_users WHERE email=$email;
            SELECT password_hash    INTO $phash1     FROM base_users WHERE email=$email;

        END IF;

        SET $phash2 = ComputeHash( $salt, $password );

        IF $phash1=$phash2 THEN
            SET $authenticated = TRUE;
        ELSE
            SET $authenticated = FALSE;
        END IF;

        IF NOT $USER THEN

            IF NOT EXISTS( SELECT * FROM base_users_invalid WHERE email=$email ) THEN
                REPLACE INTO base_users_invalid
                (  email, invalid_logins, invalid_sent )
                VALUES
                ( $email,              0,            0 );
            END IF;

            SELECT invalid_logins INTO $invalid FROM base_users_invalid WHERE email=$email;

            UPDATE base_users_invalid SET invalid_logins = invalid_logins + 1, invalid_sent=0 WHERE email=$email;

            DO SLEEP( $invalid - TIMESTAMPDIFF( SECOND, NOW(), $start ) );

            IF $invalid > 4 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_LOGINS';
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CREDENTIALS';
            END IF;

        ELSE

            SELECT email, invalid_logins INTO $email, $invalid FROM base_users WHERE USER=$USER;

            #
            #   First, if unauthenticated, update invalid_logins so that this is promplty incremented when brute-forced.
            #

            IF NOT $authenticated THEN
                UPDATE base_users SET invalid_logins = invalid_logins + 1 WHERE USER=$USER;
            END IF;

            #
            #   Second, do annoying sleep.
            #

            DO SLEEP( $invalid - TIMESTAMPDIFF( SECOND, NOW(), $start ) );

            #
            #   Third, if passed magic threshold of invalid logins fail on INVALID_LOGINS (ignore empty password).
            #

            IF $invalid > 4 AND "" != $password THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_LOGINS';
            END IF;

            #
            #   Fourth, if unauthenticated, fail on password.  
            #

            IF NOT $authenticated THEN

                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CREDENTIALS';

            ELSE

                SELECT group_code INTO $group_code FROM base_groups_members LEFT JOIN base_groups USING (GROUP_ID) WHERE USER=$USER;

                #
                #   Ensure unique sessionid
                #

                SET $sessionid = GenerateSalt();
                WHILE EXISTS( SELECT * FROM base_users_sessions WHERE sid=$sessionid ) DO
                    SET $sessionid = GenerateSalt();
                END WHILE;

                SET $csrf = GenerateSalt();
                WHILE EXISTS( SELECT * FROM base_users_sessions WHERE csrf=$csrf ) DO
                    SET $csrf = GenerateSalt();
                END WHILE;

                REPLACE INTO base_users_sessions VALUES ( $sessionid, $csrf, $USER, $email, $group_code, NOW(), NOW(), UNIX_TIMESTAMP() + 3600 );
                UPDATE base_users SET invalid_logins = 0, last_login=NOW(), visits = visits + 1 WHERE USER=$USER;

                REPLACE INTO base_users_sessions_log VALUES ( $sessionid, $USER, $email, $group_code, NOW(), NOW(), UNIX_TIMESTAMP() + 3600 );

                SELECT "OK", type INTO $status, $idtype FROM view_base_users WHERE email=$email;
            END IF;

        END IF;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Sessions_Retrieve_Current
(
  $Sid                             CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT * FROM view_base_users_sessions WHERE sessionid=$Sid;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Sessions_Terminate
(
  $Sid                             CHAR(99)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    DELETE FROM base_users_sessions WHERE sid=$Sid;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Base_Users_Sessions_Verify
(
  $Sid CHAR(64)
)
RETURNS BOOLEAN
READS SQL DATA
SQL SECURITY DEFINER
BEGIN

    DECLARE $expiry INT;
    DECLARE $now    INT;
    DECLARE $ret    BOOL DEFAULT FALSE;

    SET $now    = UNIX_TIMESTAMP();
    SET $ret    = False;

    SELECT expiry INTO $expiry FROM base_users_sessions WHERE sid=$Sid;

    IF $now < $expiry THEN
        SET $ret = True;
    END IF;

    return $ret;

END
//
DELIMITER ;
DELIMITER //
CREATE FUNCTION Users_Sessions_Verify
(
  $Sid CHAR(64)
)
RETURNS BOOLEAN
READS SQL DATA
SQL SECURITY DEFINER
BEGIN

DECLARE $expiry INT;
DECLARE $now    INT;
DECLARE $ret    BOOL DEFAULT FALSE;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SET $now    = UNIX_TIMESTAMP();
    SET $ret    = False;

    SELECT expiry INTO $expiry FROM base_users_sessions WHERE sid=$Sid;

    IF $now < $expiry THEN
        SET $ret = True;
    END IF;

END IF;

return $ret;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE base_users_sessions_extend_expiry
(
  $Sid CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $expiry   INT;
    DECLARE $now      INT;
    DECLARE $ret      BOOL;
    DECLARE read_only BOOL;

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        SELECT expiry
        INTO  $expiry
        FROM   base_users_sessions
        WHERE  sid = $Sid;

        SET $now = UNIX_TIMESTAMP();

        IF $now < $expiry THEN

            UPDATE base_users_sessions
            SET
                updated = NOW(),
                expiry  = $now + 14400

            WHERE sid = $Sid;

        ELSE

            CALL Base_Users_Sessions_Terminate( $Sid );

        END IF;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Termination_Schedule_Replace
(
  $Sid                        CHAR(64),
  $USER                        INT(11),
  $password                   CHAR(99)
)
BEGIN


IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	SET @success = 0;

	CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

	IF @USER = $USER THEN
		IF ( base_users_verify_credentials( @email, $password ) ) THEN
			REPLACE INTO base_users_termination_schedule
				( USER,  mark,  time_of_termination )
			VALUES
				( $USER, NOW(), date_add( NOW(), INTERVAL 1 DAY ) );
			SET @success = 1;

		END IF;
	END IF;

	SELECT @success AS success;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Termination_Schedule_Retrieve
()
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

	SELECT USER, time_of_termination, email
	FROM base_users_termination_schedule LEFT JOIN base_users USING (USER)
	WHERE NOW() > time_of_termination;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Tokens_Sent
(
    $token              CHAR(64)
)
SQL SECURITY DEFINER
BEGIN

UPDATE base_users_tokens SET token_sent = NOW() WHERE token = $token AND 0 = token_sent;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Tokens_Used
(
    $token              CHAR(64)
)
SQL SECURITY DEFINER
BEGIN

UPDATE base_users_tokens SET token_used = NOW() WHERE token = $token AND 0 = token_used AND NOW() <= token_expiry;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Tokens_Create
(
    $token_type         CHAR(50),
    $USER               INT,
    $token_expiry_days  INT,
OUT $token              CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

DECLARE $token_expiry  DATETIME  DEFAULT  0;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT( IsEventScheduler() OR IsRootCaller() ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Users_Tokens_Create';

ELSE

    #
    #   Ensure unique token.
    #

    SET $token = GenerateSalt();
    WHILE EXISTS( SELECT * FROM base_users_tokens WHERE token=$token ) DO
        SET $token = GenerateSalt();
    END WHILE;

    #
    #   Set 3 day token expiry
    #

    SET $token_expiry = DATE_ADD( NOW(), INTERVAL $token_expiry_days DAY );

    REPLACE INTO base_users_tokens
    (  TOKEN_ID,  USER,  token_created,  token_expiry_days,  token_expiry,  token_type,  token )
    VALUES
    (         0, $USER,          NOW(), $token_expiry_days, $token_expiry, $token_type, $token );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE base_users_uid_create( $Type VARCHAR(20) )
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    INSERT INTO base_users_uids (type) VALUES ( $Type );
    SELECT LAST_INSERT_ID() AS USER;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Device_Logins
(
    $USER_DEVICE_LOGIN_ID       INT,
    $order                      TEXT,
    $limit                      INT,
    $offset                     INT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    CALL CheckLimitOffset( $limit, $offset );

    IF 'USER_DEVICE_LOGIN_ID' = $order OR '' = $order THEN

        SELECT   *
        FROM     base_users_device_logins
        WHERE    user_device_login_deleted = 0
        AND      (0  = $USER_DEVICE_LOGIN_ID     OR USER_DEVICE_LOGIN_ID      = $USER_DEVICE_LOGIN_ID)
        ORDER BY USER_DEVICE_LOGIN_ID
        LIMIT    $limit
        OFFSET   $offset;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Device_Logins_Replace
(
    $USER                       INT,
    $USER_DEVICE_LOGIN_ID       INT,
    $user_device_login_guid     CHAR(36),
    $user_device_login_salt     TEXT,
    $user_device_login_hash     TEXT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        IF NOT $USER_DEVICE_LOGIN_ID THEN

            REPLACE INTO base_users_device_logins
            ( USER,  USER_DEVICE_LOGIN_ID)
            VALUES
            ($USER, $USER_DEVICE_LOGIN_ID);

            SET $USER_DEVICE_LOGIN_ID = LAST_INSERT_ID();

        END IF;

        UPDATE base_users_device_logins
        SET
            user_device_login_guid    = $user_device_login_guid,
            user_device_login_salt    = $user_device_login_salt,
            user_device_login_hash    = $user_device_login_hash

        WHERE user_device_login_deleted = 0
        AND   USER_DEVICE_LOGIN_ID      = $USER_DEVICE_LOGIN_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Users_Device_Logins_Delete
(
    $USER_DEVICE_LOGIN_ID  INT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        UPDATE base_users_device_logins
        SET
            user_device_login_deleted = NOW()

        WHERE user_device_login_deleted = 0
        AND   USER_DEVICE_LOGIN_ID      = $USER_DEVICE_LOGIN_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Web_Connections_Create_Out
(
    $apikey                  CHAR(64),
    $connection_server_name  CHAR(99),
    $connection_ip_remote    CHAR(45),
OUT $connection_csrf_token   CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

    DECLARE $CONNECTION_ID           INT       DEFAULT 0;
    DECLARE $connection_csrf_expiry  DATETIME  DEFAULT 0;

    CALL Base_Users_Authorise_Sessionid_Or_APIKey( '', $apikey, @email, @USER, @idtype );

    IF NOT( "ADMIN" = @idtype ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Web_Connections_Create_Out';

    ELSE

        SELECT   CONNECTION_ID,  connection_csrf_token
        INTO    $CONNECTION_ID, $connection_csrf_token
        FROM     base_web_connections
        WHERE    connection_server_name = $connection_server_name
        AND      connection_ip_remote   = $connection_ip_remote
        AND      NOW()                  < DATE_SUB( connection_csrf_expiry, INTERVAL 10 MINUTE )
        ORDER BY connection_csrf_expiry DESC
        LIMIT    1;

        IF NOT $CONNECTION_ID THEN

            SET $connection_csrf_token  = GenerateSalt();
            SET $connection_csrf_expiry = DATE_ADD( NOW(), INTERVAL 1 HOUR );

            REPLACE INTO base_web_connections
            (  CONNECTION_ID,  connection_server_name,  connection_ip_remote )
            VALUES
            (              0, $connection_server_name, $connection_ip_remote );
            SET $CONNECTION_ID = LAST_INSERT_ID();

            UPDATE base_web_connections
            SET
                connection_csrf_token  = $connection_csrf_token,
                connection_csrf_expiry = $connection_csrf_expiry

            WHERE CONNECTION_ID = $CONNECTION_ID;

        END IF;

    END IF;

    DELETE FROM base_web_connections WHERE connection_csrf_expiry < NOW();

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Files_Retrieve_By_Token
(
  $Sid                             CHAR(64),
  $token                           CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT * FROM base_files WHERE token=$token ORDER BY version DESC LIMIT 1;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Files_Replace
(
  $Sid                             CHAR(64),
  $FILE                             INT(11),
  $USER                             INT(11),
  $kind                            CHAR(30),
  $original_filename               CHAR(255),
  $filename                        CHAR(255),
  $filetype                        CHAR(99),
  $filesize                        CHAR(45),
  $fileextension                   CHAR(10),
  $base64                      LONGBLOB
)
SQL SECURITY INVOKER
BEGIN

DECLARE $FILE  INT   DEFAULT  0;
DECLARE $salt  TEXT  DEFAULT '';
DECLARE $token TEXT  DEFAULT '';

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT( $USER = @USER OR "ADMIN" = @idtype OR IsLocalCaller() ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Files_Replace';

ELSE

    SET $token = GenerateSalt();

    WHILE EXISTS( SELECT * FROM base_files WHERE token=$token ) DO
        SET $token = GenerateSalt();
    END WHILE;

    SET $base64 = REPLACE( $base64, ' ', '+' );

    REPLACE INTO base_files
    (  FILE,  USER,  version,  kind,  original_filename,  filename,  filetype,  filesize,  fileextension,  salt,  token,  base64 )
    VALUES
    ( $FILE, $USER,    NOW(), $kind, $original_filename, $filename, $filetype, $filesize, $fileextension,     0, $token, $base64 );

    IF NOT $FILE THEN
        SELECT LAST_INSERT_ID() INTO $FILE;
    END IF;

    SELECT $FILE AS FILE;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Files_Retrieve_Info_By_Kind
(
  $Sid                             CHAR(64),
  $USER                             INT(11),
  $kind                            CHAR(30)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF $USER = @USER OR "ADMIN" = @idtype THEN

      SELECT * FROM view_files WHERE USER=$USER AND kind=$kind ORDER BY version DESC;

    ELSE

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION';

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Files_Retrieve
(
  $Sid                             CHAR(64),
  $FILE                             INT(11)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    SELECT * FROM base_files WHERE USER=@USER AND FILE=$FILE ORDER BY version DESC LIMIT 1;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Groups_Create
(
    $Sid               CHAR(64),
    $group_name        CHAR(99),
    $group_code        CHAR(50)
)
BEGIN

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT IsRootCaller() AND NOT @USER THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Groups_Create';

ELSE

    REPLACE INTO base_groups
    (  GROUP_ID,  GROUP_OWNER,  group_created,  group_name,  group_code )
    VALUES
    (         0,        @USER,          NOW(), $group_name, $group_code );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Groups_Members_Add
(
    $Sid               CHAR(64),
    $GROUP_ID          INT,
    $USER              INT,
    $group_owner       BOOL
)
BEGIN

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT @USER THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Groups_Members_Add';

ELSEIF NOT( "ADMIN" = @idtype OR EXISTS( SELECT * FROM base_groups WHERE GROUP_ID=$GROUP_ID AND GROUP_OWNER = @USER ) ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Groups_Members_Add';

ELSE

    REPLACE INTO base_groups_members
    (  GROUP_ID,  USER,  group_owner )
    VALUES
    ( $GROUP_ID, $USER, $group_owner );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_GUIDs_Create
(
    $guid_type  CHAR(50),
    $REF_ID     INT,
OUT $guid       CHAR(36)
)
BEGIN

DECLARE $GUID_ID      INT   DEFAULT  1;
DECLARE $LOCK_STRING  TEXT  DEFAULT "";

SET $LOCK_STRING = "Base_GUIDs_Create";
SET $guid        = "";

IF GET_LOCK( $LOCK_STRING, 10 ) THEN

    SET @MAX_GUID = NULL;
    SELECT MAX( GUID_ID ) + 1 INTO @MAX_GUID FROM base_guids;
    IF NOT ISNULL( @MAX_GUID ) THEN
        SET $GUID_ID = @MAX_GUID;
    END IF;

    SET $guid = UUID();
    WHILE EXISTS( SELECT * FROM base_guids WHERE guid = $guid ) DO

        SET $guid = UUID();

    END WHILE;

    REPLACE INTO base_guids
    (  GUID_ID,  guid,  guid_created,  guid_type,  REF_ID )
    VALUES
    ( $GUID_ID, $guid,         NOW(), $guid_type, $REF_ID );

    WHILE NOT RELEASE_LOCK( $LOCK_STRING ) DO
        SET @nop = 0;
    END WHILE;

    SET @LAST_INSERT_GUID = $guid;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Logs
(
  $sid          CHAR(64),
  $after         INT(11)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid( $sid, @email, @USER, @idtype );

IF "ADMIN" = @idtype THEN

  IF $after THEN

    SELECT * FROM base_logs WHERE $after < LOG_ID ORDER BY LOG_ID LIMIT 50000;

  ELSE

    SELECT * FROM (SELECT * FROM base_logs ORDER BY LOG_ID DESC LIMIT 50000) AS S1 ORDER BY CALL_ID, LOG_ID;

  END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Logs_Prime
(
      $sid       CHAR(64),
INOUT $CALL_ID    INT(11),
      $level     CHAR(20),
      $source        TEXT,
      $message       TEXT
)
SQL SECURITY INVOKER
BEGIN

SELECT MAX( CALL_ID ) INTO $CALL_ID FROM base_logs;

IF ISNULL( $CALL_ID ) THEN
  SET $CALL_ID = 0;
END IF;

SET $CALL_ID = $CALL_ID + 1;

INSERT INTO base_logs
  (  LOG_ID,  CALL_ID,  sessionid, logged,  level,  source,  message )
VALUES
  (       0, $CALL_ID,       $sid,  NOW(), $level, $source, $message );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Logs_Append
(
  $sid          CHAR(64),
  $CALL_ID       INT(11),
  $level        CHAR(20),
  $source           TEXT,
  $message          TEXT
)
SQL SECURITY INVOKER
BEGIN

IF $CALL_ID THEN

    INSERT INTO base_logs
      (  LOG_ID,  CALL_ID,  sessionid,  logged,  level,  source,  message )
    VALUES
      (       0, $CALL_ID,       $sid,   NOW(), $level, $source, $message );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64),
  $PLACE_ID                        TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT @USER THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places';

ELSEIF $PLACE_ID THEN

    SELECT
        base_places.*,
        IFNULL( description,                                      '' ) AS description,
        IF(0=place_confirmed, 'warning',            '' ) AS css_class,
        IF(0=place_confirmed, '&times;', '&checkmark;' ) AS confirmed

    FROM     base_places
    LEFT JOIN
    (
        SELECT
            PLACE_SUGGESTION_ID AS CONFIRMED_PLACE_SUGGESTION_ID,
            description

        FROM base_places_suggestions
    ) AS S1 USING (CONFIRMED_PLACE_SUGGESTION_ID)
    WHERE    PLACE_ID=$PLACE_ID;

ELSE

    SELECT
        base_places.*,
        IFNULL( nr_suggestions,                                    0 ) AS nr_suggestions,
        IFNULL( description,                                      '' ) AS description,
        IF(0=place_confirmed, 'warning',            '' ) AS css_class,
        IF(0=place_confirmed, '&times;', '&checkmark;' ) AS confirmed

    FROM     base_places
    LEFT JOIN
    (
        SELECT PLACE_ID, COUNT(*) AS nr_suggestions
        FROM base_places_suggestions
        GROUP BY PLACE_ID

    ) AS S0 USING (PLACE_ID)
    LEFT JOIN
    (
        SELECT
            PLACE_SUGGESTION_ID AS CONFIRMED_PLACE_SUGGESTION_ID,
            description

        FROM base_places_suggestions
    ) AS S1 USING (CONFIRMED_PLACE_SUGGESTION_ID)
    ORDER BY suburb, PLACE_ID;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Autocomplete
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64),
  $input                           TEXT,
  $google_place_id                 TEXT,
  $floor                           CHAR(10),
  $street_number                   CHAR(10),
  $street                          CHAR(99),
  $suburb                          CHAR(99),
  $city                            CHAR(99),
  $state                           CHAR(99),
  $country                         CHAR(99),
  $postal_code                     CHAR(10),
  $latitude                        TEXT,
  $longitude                       TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $PLACE_ID INT DEFAULT 0;

CALL Base_Places_Autocomplete_Inout
(
    $Sid,
    $apikey,
    $input,
    $google_place_id,
    $floor,
    $street_number,
    $street,
    $suburb,
    $city,
    $state,
    $country,
    $postal_code,
    $latitude,
    $longitude,
    $PLACE_ID
);

CALL Base_Places( $Sid, $apikey, $PLACE_ID );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Unprocessed
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT "ADMIN" = @idtype AND NOT( "LOCAL" = $Sid AND IsLocalCaller() ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Unprocessed';

ELSE

    SELECT *
    FROM   base_places
    WHERE  0=place_processed;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Save
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64),
  $PLACE_ID                        INT,
  $name                            TEXT,
  $value                           TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT( "ADMIN" = @idtype OR "CLIENT" = @idtype OR "LOCAL" = $Sid AND IsLocalCaller() ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Save';

    ELSE

        CASE $name
        WHEN "CONFIRMED_PLACE_SUGGESTION_ID"   THEN UPDATE base_places SET place_confirmed                 = NOW(), CONFIRMED_PLACE_SUGGESTION_ID = $value WHERE PLACE_ID=$PLACE_ID;
        WHEN "place_processed"                 THEN UPDATE base_places SET place_processed                 = NOW()                                         WHERE PLACE_ID=$PLACE_ID;
        WHEN "place_error"                     THEN UPDATE base_places SET place_error                     = $value                                        WHERE PLACE_ID=$PLACE_ID;
        WHEN "route_shortest_distance_metres"  THEN UPDATE base_places SET route_shortest_distance_metres  = $value                                        WHERE PLACE_ID=$PLACE_ID;
        WHEN "route_shortest_duration_seconds" THEN UPDATE base_places SET route_shortest_duration_seconds = $value                                        WHERE PLACE_ID=$PLACE_ID;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CASE IN Base_Places_Save';
        END CASE;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Override
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64),
  $PLACE_ID                        INT,
  $OVERRIDE_PLACE_ID               INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $GROUP_ID                       INT       DEFAULT  0;
DECLARE $input                          TEXT      DEFAULT '';
DECLARE $suggested_google_place_id      TEXT      DEFAULT '';
DECLARE $CONFIRMED_PLACE_SUGGESTION_ID  INT       DEFAULT  0;
DECLARE $floor                          TEXT      DEFAULT '';
DECLARE $street_number                  TEXT      DEFAULT '';
DECLARE $street                         TEXT      DEFAULT '';
DECLARE $suburb                         TEXT      DEFAULT '';
DECLARE $city                           TEXT      DEFAULT '';
DECLARE $state                          TEXT      DEFAULT '';
DECLARE $country                        TEXT      DEFAULT '';
DECLARE $postal_code                    TEXT      DEFAULT '';
DECLARE $latitude                       FLOAT     DEFAULT  0;
DECLARE $longitude                      FLOAT     DEFAULT  0;
DECLARE $place_created                  DATETIME  DEFAULT  0;
DECLARE $place_processed                DATETIME  DEFAULT  0;
DECLARE $place_confirmed                DATETIME  DEFAULT  0;

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF NOT( @USER OR ("LOCAL" = $Sid AND IsLocalCaller() ) ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Override';

ELSE

    SELECT
        GROUP_ID,
        input,
        suggested_google_place_id,
        CONFIRMED_PLACE_SUGGESTION_ID,
        floor,
        street_number,
        street,
        suburb,
        city,
        state,
        country,
        postal_code,
        latitude,
        longitude,
        place_created,
        place_processed,
        place_confirmed

    INTO
        $GROUP_ID,
        $input,
        $suggested_google_place_id,
        $CONFIRMED_PLACE_SUGGESTION_ID,
        $floor,
        $street_number,
        $street,
        $suburb,
        $city,
        $state,
        $country,
        $postal_code,
        $latitude,
        $longitude,
        $place_created,
        $place_processed,
        $place_confirmed

    FROM base_places
    WHERE PLACE_ID = $OVERRIDE_PLACE_ID;

    UPDATE base_places
    SET
        GROUP_ID                      = $GROUP_ID,
        input                         = $input,
        suggested_google_place_id     = $suggested_google_place_id,
        CONFIRMED_PLACE_SUGGESTION_ID = $CONFIRMED_PLACE_SUGGESTION_ID,
        floor                         = $floor,
        street_number                 = $street_number,
        street                        = $street,
        suburb                        = $suburb,
        city                          = $city,
        state                         = $state, 
        country                       = $country,
        postal_code                   = $postal_code,
        latitude                      = $latitude,
        longitude                     = $longitude,
        place_created                 = $place_created,
        place_processed               = $place_processed,
        place_confirmed               = $place_confirmed

    WHERE PLACE_ID = $PLACE_ID;        

    IF $PLACE_ID != $OVERRIDE_PLACE_ID THEN
        DELETE FROM base_places_suggestions WHERE PLACE_ID=$PLACE_ID;
    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Update
(
    $Sid                             CHAR(64),
    $apikey                          CHAR(64),
    $PLACE_ID                        INT,
    $google_place_id                 TEXT,
    $floor                           CHAR(10),
    $street_number                   CHAR(10),
    $street                          CHAR(99),
    $suburb                          CHAR(99),
    $city                            CHAR(99),
    $state                           CHAR(99),
    $country                         CHAR(99),
    $postal_code                     CHAR(10),
    $latitude                        TEXT,
    $longitude                       TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $CONFIRMED_PLACE_SUGGESTION_ID  INT       DEFAULT 0;
DECLARE $place_geocoded                 DATETIME  DEFAULT 0;
DECLARE $place_confirmed                DATETIME  DEFAULT 0;

SELECT  PLACE_SUGGESTION_ID
INTO   $CONFIRMED_PLACE_SUGGESTION_ID
FROM    base_places_suggestions
WHERE   PLACE_ID        = $PLACE_ID
AND     google_place_id = $google_place_id
ORDER BY PLACE_SUGGESTION_ID DESC
LIMIT    1;

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT "ADMIN" = @idtype THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Update';

ELSEIF NOT $PLACE_ID OR "" = $google_place_id THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Places_Update';

ELSE

    IF "" != $street AND "" != $suburb AND "" != $state AND "" != $country AND "" != $postal_code AND "" != $latitude AND "" != $longitude THEN
        SET $place_geocoded = NOW();
    END IF;

    IF "" != $street_number AND "" != $street AND "" != $suburb AND "" != $state AND "" != $country AND "" != $postal_code AND "" != $latitude AND "" != $longitude THEN
        SET $place_confirmed = NOW();
    END IF;

    UPDATE base_places
    SET 
        suggested_google_place_id     = $google_place_id,
        CONFIRMED_PLACE_SUGGESTION_ID = $CONFIRMED_PLACE_SUGGESTION_ID,
        floor                         = $floor,
        street_number                 = $street_number,
        street                        = $street,
        suburb                        = $suburb,
        city                          = $city,
        state                         = $state,
        country                       = $country,
        postal_code                   = $postal_code,
        latitude                      = $latitude, 
        longitude                     = $longitude,
        place_processed               = NOW(),
        place_geocoded                = $place_geocoded,
        place_confirmed               = $place_confirmed

    WHERE PLACE_ID=$PLACE_ID;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Suggestions
(
  $Sid                  CHAR(64),
  $PLACE_ID             INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $confirmed  BOOL  DEFAULT 0;

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF NOT @USER THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Suggestions_Unconfirmed';

ELSE

    SET $confirmed = EXISTS( SELECT * FROM base_places WHERE PLACE_ID=$PLACE_ID AND NOT CONFIRMED_PLACE_SUGGESTION_ID = 0);

    SELECT
        *,
        IF( $confirmed, 'disabled', '' ) AS disabled

    FROM      base_places_suggestions
    WHERE     PLACE_ID = $PLACE_ID
    ORDER BY  description;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Suggestions_Replace
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64),
  $PLACE_SUGGESTION_ID             INT,
  $PLACE_ID                        INT,
  $google_place_id                 TEXT,
  $description                     TEXT,
  $main_text                       TEXT,
  $secondary_text                  TEXT,
  $types                           TEXT,

  $suggestion_type                 TEXT,
  $suggestion_floor                TEXT,
  $suggestion_street_number        TEXT,
  $suggestion_street               TEXT,
  $suggestion_suburb               TEXT,
  $suggestion_city                 TEXT,
  $suggestion_state                TEXT,
  $suggestion_country              TEXT,
  $suggestion_postal_code          TEXT,

  $suggestion_latitude             FLOAT,
  $suggestion_longitude            FLOAT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT @USER THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Suggestions_Replace';

ELSE

    IF NOT EXISTS( SELECT * FROM base_places_suggestions WHERE PLACE_ID=$PLACE_ID AND google_place_id=$google_place_id ) THEN

        REPLACE INTO base_places_suggestions
        (  PLACE_SUGGESTION_ID,  PLACE_ID,  google_place_id,  description,  main_text,  secondary_text,  types,  suggestion_created )
        VALUES
        (                    0, $PLACE_ID, $google_place_id, $description, $main_text, $secondary_text, $types,               NOW() );

        SET $PLACE_SUGGESTION_ID = LAST_INSERT_ID();

        UPDATE base_places_suggestions
        SET
            suggestion_type          = $suggestion_type,
            suggestion_floor         = $suggestion_floor,
            suggestion_street_number = $suggestion_street_number,
            suggestion_street        = $suggestion_street,
            suggestion_suburb        = $suggestion_suburb,
            suggestion_city          = $suggestion_city,
            suggestion_state         = $suggestion_state,
            suggestion_country       = $suggestion_country,
            suggestion_postal_code   = $suggestion_postal_code

        WHERE PLACE_SUGGESTION_ID = $PLACE_SUGGESTION_ID;

        SELECT * FROM base_places_suggestions WHERE PLACE_SUGGESTION_ID=$PLACE_SUGGESTION_ID;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Create_Inout
(
    $Sid                             CHAR(64),
    $apikey                          CHAR(64),
    $input                           TEXT,
    $google_place_id                 TEXT,
OUT $PLACE_ID                        INT
)
SQL SECURITY DEFINER
BEGIN

SET $PLACE_ID = 0;

IF NOT "" = $google_place_id THEN
    SELECT PLACE_ID INTO $PLACE_ID FROM base_places WHERE NOT 0=place_confirmed AND input=$input AND suggested_google_place_id = $google_place_id ORDER BY PLACE_ID DESC LIMIT 1;
END IF;

IF NOT $PLACE_ID THEN
    SELECT PLACE_ID INTO $PLACE_ID FROM base_places WHERE NOT 0=place_confirmed AND input = $input ORDER BY PLACE_ID DESC LIMIT 1;
END IF;

IF NOT $PLACE_ID THEN
    SELECT PLACE_ID INTO $PLACE_ID FROM base_places WHERE input=$input AND suggested_google_place_id = $google_place_id ORDER BY PLACE_ID DESC LIMIT 1;
END IF;

IF NOT $PLACE_ID THEN
    SELECT PLACE_ID INTO $PLACE_ID FROM base_places WHERE input=$input ORDER BY PLACE_ID DESC LIMIT 1;
END IF;

#
#   Only create new place if could not retrieve place id!
#   The above clauses must also match those in the Base_Places_Autocomplete_Inout
#

IF NOT $PLACE_ID THEN

    CALL Base_Places_Autocomplete_Inout
    (
        $Sid,
        $apikey,
        $input,
        $google_place_id, # google_place_id
        '',               # floor
        '',               # street_number
        '',               # street
        '',               # suburb
        '',               # city
        '',               # state
        '',               # country
        '',               # postal_code
        '',               # latitude
        '',               # longitude
        $PLACE_ID );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Autocomplete_Inout
(
    $Sid                             CHAR(64),
    $apikey                          CHAR(64),
    $input                           TEXT,
    $google_place_id                 TEXT,
    $floor                           CHAR(10),
    $street_number                   CHAR(10),
    $street                          CHAR(99),
    $suburb                          CHAR(99),
    $city                            CHAR(99),
    $state                           CHAR(99),
    $country                         CHAR(99),
    $postal_code                     CHAR(10),
    $latitude                        TEXT,
    $longitude                       TEXT,
OUT $PLACE_ID                        INT
)
SQL SECURITY INVOKER
BEGIN

DECLARE $GROUP_ID         INT            DEFAULT 0;
DECLARE $place_processed  DATETIME       DEFAULT 0;
DECLARE $place_geocoded   DATETIME       DEFAULT 0;
DECLARE $place_confirmed  DATETIME       DEFAULT 0;
DECLARE $lat              DECIMAL(10,7)  DEFAULT 0;
DECLARE $lng              DECIMAL(10,7)  DEFAULT 0;

SET $PLACE_ID = 0;
SET $lat      = $latitude;
SET $lng      = $longitude;

IF NOT "" = $google_place_id THEN
    SELECT PLACE_ID INTO $PLACE_ID FROM base_places WHERE NOT 0=place_confirmed AND input=$input AND suggested_google_place_id = $google_place_id ORDER BY PLACE_ID DESC LIMIT 1;
END IF;

IF NOT $PLACE_ID THEN
    SELECT PLACE_ID INTO $PLACE_ID FROM base_places WHERE NOT 0=place_confirmed AND input = $input ORDER BY PLACE_ID DESC LIMIT 1;
END IF;

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT @USER THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Autocomplete';

ELSE

    SELECT GROUP_ID INTO $GROUP_ID FROM base_groups_members WHERE USER=@USER;

    IF NOT $PLACE_ID THEN

        REPLACE INTO base_places ( PLACE_ID, place_created ) VALUES ( 0, NOW() );
        SET $PLACE_ID = LAST_INSERT_ID();

        IF "" != $street_number AND "" != $street AND "" != $suburb AND "" != $city AND "" != $state AND "" != $country AND "" != $postal_code AND "" != $latitude AND "" != $longitude THEN
            SET $place_processed = NOW();
            SET $place_confirmed = NOW();
        END IF;

        IF "" != $street AND "" != $suburb AND "" != $city AND "" != $state AND "" != $country AND "" != $postal_code AND "" != $latitude AND "" != $longitude THEN
            SET $place_geocoded = NOW();
        END IF;

        UPDATE base_places
        SET
            GROUP_ID                  = $GROUP_ID,
            input                     = $input,
            suggested_google_place_id = $google_place_id,
            floor                     = $floor,
            street_number             = $street_number,
            street                    = $street,
            suburb                    = $suburb,
            city                      = $city,
            state                     = $state,
            country                   = $country,
            postal_code               = $postal_code,
            latitude                  = $latitude,
            longitude                 = $longitude,
            place_processed           = $place_processed,
            place_geocoded            = $place_geocoded,
            place_confirmed           = $place_confirmed

        WHERE PLACE_ID=$PLACE_ID;

    ELSE

        UPDATE base_places
        SET
            street_number             = $street_number,
            latitude                  = $latitude,
            longitude                 = $longitude

        WHERE PLACE_ID=$PLACE_ID;

    END IF;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Incomplete
(
  $Sid                             CHAR(64)
)
SQL SECURITY INVOKER
BEGIN

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT( "LOCAL" = $Sid AND IsLocalCaller() ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Incomplete';

ELSE

    SELECT *
    FROM   base_places
    WHERE  NOT 0=CONFIRMATION_PLACE_SUGGESTION_ID
    AND    "" = postal_code;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Manually_Matched
(
  $Sid                             CHAR(64),
  $apikey                          CHAR(64)
)
SQL SECURITY DEFINER
BEGIN

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF NOT "ADMIN" = @idtype AND NOT( "LOCAL" = $Sid AND IsLocalCaller() ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Manually_Matched';

ELSE

    SELECT
        PLACE_ID,
        CONFIRMED_PLACE_SUGGESTION_ID,
        street,
        suggested_google_place_id,
        google_place_id

    FROM   base_places
    LEFT JOIN
    (
        SELECT *, PLACE_SUGGESTION_ID AS CONFIRMED_PLACE_SUGGESTION_ID
        FROM base_places_suggestions
    ) AS S0 USING (PLACE_ID, CONFIRMED_PLACE_SUGGESTION_ID)
    WHERE NOT CONFIRMED_PLACE_SUGGESTION_ID = 0
    AND   '' = street
    AND   NOT ISNULL( google_place_id );

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Suggestions_Unconfirmed
(
  $Sid                             CHAR(64),
  $PLACE_SUGGESTION_ID             INT
)
SQL SECURITY INVOKER
BEGIN

CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT( "ADMIN" = @idtype  ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Suggestions_Unconfirmed';

ELSE

    SELECT    *
    FROM      base_places_suggestions
    LEFT JOIN base_places USING (PLACE_ID)
    WHERE     0 = CONFIRMATION_PLACE_SUGGESTION_ID
    ORDER BY  PLACE_ID, CONFIRMATION_PLACE_SUGGESTION_ID;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Routes
(
    $Sid                     CHAR(64),
    $apikey                  CHAR(64),
    $PLACE_OGN_ID            INT,
    $PLACE_DST_ID            INT,
    $filter                  TEXT,
    $limit                   INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    SET @offset = 0;

    CALL CheckLimitOffset( $limit, @offset );

    CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

    IF NOT @USER THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Routes';

    ELSEIF $PLACE_OGN_ID AND $PLACE_DST_ID THEN

        IF EXISTS( SELECT * FROM base_places_routes WHERE PLACE_OGN_ID = $PLACE_OGN_ID AND PLACE_DST_ID = $PLACE_DST_ID AND NOT route_processed = 0 ) THEN

            SELECT * FROM base_places_routes WHERE PLACE_OGN_ID = $PLACE_OGN_ID AND PLACE_DST_ID = $PLACE_DST_ID AND NOT route_processed = 0 ORDER BY ROUTE_ID LIMIT 1;

        ELSEIF EXISTS( SELECT * FROM base_places_routes WHERE PLACE_OGN_ID = $PLACE_DST_ID AND PLACE_DST_ID = $PLACE_OGN_ID AND NOT route_processed = 0 ) THEN

            BEGIN

                DECLARE $route_distance_metres   INT  DEFAULT 0;
                DECLARE $route_distance_seconds  INT  DEFAULT 0;

                SELECT
                     route_distance_metres,  route_distance_seconds
                INTO
                    $route_distance_metres, $route_distance_seconds
                FROM base_places_routes
                WHERE PLACE_OGN_ID = $PLACE_DST_ID AND PLACE_DST_ID = $PLACE_OGN_ID AND NOT route_processed = 0
                ORDER BY ROUTE_ID LIMIT 1;

                CALL Base_Places_Routes_Create
                (
                    $Sid,
                    $apikey,
                    $PLACE_OGN_ID,
                    $PLACE_DST_ID,
                    $route_distance_metres,
                    $route_duration_seconds
                );

            END;

            SELECT * FROM base_places_routes WHERE PLACE_OGN_ID = $PLACE_OGN_ID AND PLACE_DST_ID = $PLACE_DST_ID AND NOT route_processed = 0 ORDER BY ROUTE_ID LIMIT 1;

        END IF;

    ELSEIF $filter = "sans" THEN

        SELECT   *
        FROM     base_places_routes
        LEFT JOIN
        (
            SELECT
                PLACE_ID AS PLACE_OGN_ID,
                latitude AS place_ogn_lat,
                longitude AS place_ogn_lng

            FROM base_places
        ) AS S1 USING (PLACE_OGN_ID)
        LEFT JOIN
        (
            SELECT
                PLACE_ID AS PLACE_DST_ID,
                latitude AS place_dst_lat,
                longitude AS place_dst_lng

            FROM base_places
        ) AS S2 USING (PLACE_DST_ID)
        WHERE    0 = route_shortest_distance_metres
        ORDER BY ROUTE_ID
        LIMIT    $limit;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Routes_Unprocessed
(
    $Sid                     CHAR(64),
    $apikey                  CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT "ADMIN" = @idtype AND NOT( "LOCAL" = $Sid AND IsLocalCaller() ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Routes_Unprocessed';

ELSE

    SELECT ROUTE_ID, PLACE_OGN_ID, PLACE_DST_ID, origin_place_id, destination_place_id
    FROM
    (
        SELECT *
        FROM   base_places_routes
        WHERE (0 = route_distance_metres OR 0 = route_duration_seconds)
        AND    PLACE_OGN_ID != PLACE_DST_ID
    ) AS S0
    LEFT JOIN
    (
        SELECT PLACE_ID AS PLACE_OGN_ID, suggested_google_place_id AS origin_place_id
        FROM   base_places
        WHERE  NOT 0 = place_confirmed

    ) AS S1 USING (PLACE_OGN_ID)
    LEFT JOIN
    (
        SELECT PLACE_ID AS PLACE_DST_ID, suggested_google_place_id AS destination_place_id
        FROM   base_places
        WHERE  NOT 0 = place_confirmed

    ) AS S2 USING (PLACE_DST_ID)
    WHERE NOT ISNULL(origin_place_id) AND NOT ISNULL(destination_place_id) AND route_processed = 0;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Routes_Create
(
    $Sid                     CHAR(64),
    $apikey                  CHAR(64),
    $PLACE_OGN_ID            INT,
    $PLACE_DST_ID            INT,
    $route_distance_metres   INT,
    $route_duration_seconds  INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $ROUTE1_ID        INT       DEFAULT 0;
    DECLARE $ROUTE2_ID        INT       DEFAULT 0;
    DECLARE $GROUP1_ID        INT       DEFAULT 0;
    DECLARE $GROUP2_ID        INT       DEFAULT 0;
    DECLARE $route_processed  DATETIME  DEFAULT 0;

    CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

    SELECT GROUP_ID INTO $GROUP1_ID FROM base_places WHERE PLACE_ID=$PLACE_OGN_ID;
    SELECT GROUP_ID INTO $GROUP2_ID FROM base_places WHERE PLACE_ID=$PLACE_DST_ID;

    SET $route_processed = NOW();

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT @USER THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Routes_Create';

    #ELSEIF NOT( $GROUP1_ID AND $GROUP2_ID AND $GROUP1_ID = $GROUP2_ID ) THEN
    #
    #    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Places_Routes_Create';
    #
    #ELSEIF NOT Base_Groups_Members_Contains( $GROUP1_ID, @USER ) THEN
    #
    #    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Routes_Create';
    #
    ELSE

        SELECT ROUTE_ID
        INTO  $ROUTE1_ID
        FROM   base_places_routes
        WHERE  PLACE_OGN_ID = $PLACE_OGN_ID
        AND    PLACE_DST_ID = $PLACE_DST_ID
        ORDER BY route_processed DESC
        LIMIT 1;

        SELECT ROUTE_ID
        INTO  $ROUTE2_ID
        FROM   base_places_routes
        WHERE  PLACE_OGN_ID = $PLACE_DST_ID
        AND    PLACE_DST_ID = $PLACE_OGN_ID
        ORDER BY route_processed DESC
        LIMIT 1;

        IF NOT $ROUTE1_ID THEN

            REPLACE INTO base_places_routes
            (  ROUTE_ID,   GROUP_ID,  PLACE_OGN_ID,  PLACE_DST_ID,  route_created,  route_processed,  route_distance_metres,  route_duration_seconds )
            VALUES
            (         0, $GROUP1_ID, $PLACE_OGN_ID, $PLACE_DST_ID,          NOW(), $route_processed, $route_distance_metres, $route_duration_seconds );
            SET $ROUTE1_ID = LAST_INSERT_ID();

        END IF;

        IF NOT $ROUTE2_ID THEN

            REPLACE INTO base_places_routes
            (  ROUTE_ID,   GROUP_ID,  PLACE_OGN_ID,  PLACE_DST_ID,  route_created,  route_processed,  route_distance_metres,  route_duration_seconds )
            VALUES
            (         0, $GROUP1_ID, $PLACE_DST_ID, $PLACE_OGN_ID,          NOW(), $route_processed, $route_distance_metres, $route_duration_seconds );
            SET $ROUTE2_ID = LAST_INSERT_ID();

        END IF;

        IF NOT 0 = $route_distance_metres THEN

            UPDATE base_places_routes
            SET
                route_distance_metres  = $route_distance_metres,
                route_duration_seconds = $route_duration_seconds

            WHERE ROUTE_ID              = $ROUTE1_ID
            AND   route_distance_metres = 0;

            UPDATE base_places_routes
            SET
                route_distance_metres  = $route_distance_metres,
                route_duration_seconds = $route_duration_seconds

            WHERE ROUTE_ID              = $ROUTE2_ID
            AND   route_distance_metres = 0;

        END IF;

        UPDATE base_places_routes
        SET
            route_processed = $route_processed

        WHERE ROUTE_ID = $ROUTE1_ID;

        UPDATE base_places_routes
        SET
            route_processed = $route_processed

        WHERE ROUTE_ID = $ROUTE2_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Places_Routes_Save
(
    $Sid                     CHAR(64),
    $apikey                  CHAR(64),
    $ROUTE_ID                INT,
    $field                   TEXT,
    $value                   TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $GROUP_ID  INT  DEFAULT 0;

CALL Base_Users_Authorise_Sessionid_Or_APIKey( $Sid, $apikey, @email, @USER, @idtype );

SELECT GROUP_ID INTO $GROUP_ID FROM base_places_routes WHERE ROUTE_ID=$ROUTE_ID;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSEIF NOT( "ADMIN" = @idtype OR Base_Groups_Members_Contains( $GROUP_ID, @USER ) ) THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Places_Routes_Save';

ELSE

    CASE $field
    WHEN 'route_distance_metres'           THEN UPDATE base_places_routes SET route_distance_metres           = $value, route_processed=NOW() WHERE ROUTE_ID=$ROUTE_ID;
    WHEN 'route_duration_seconds'          THEN UPDATE base_places_routes SET route_duration_seconds          = $value, route_processed=NOW() WHERE ROUTE_ID=$ROUTE_ID;
    WHEN 'route_shortest_distance_metres'  THEN UPDATE base_places_routes SET route_shortest_distance_metres  = $value                        WHERE ROUTE_ID=$ROUTE_ID;
    WHEN 'route_shortest_duration_seconds' THEN UPDATE base_places_routes SET route_shortest_duration_seconds = $value                        WHERE ROUTE_ID=$ROUTE_ID;
    ELSE

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CASE_OPTION IN Base_Places_Routes_Save';
    
    END CASE;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Auth_Login
(
    $apikey        TEXT,
    $deviceid      TEXT,
    $username      TEXT,
    $password      TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $status     TEXT  DEFAULT '';
    DECLARE $sessionid  TEXT  DEFAULT '';
    DECLARE $idtype     TEXT  DEFAULT '';
    DECLARE $USER       INT   DEFAULT  0;

    CALL Base_Users_Sessions_Replace_w_DeviceID_Inout
    (
        TRIM( $deviceid ),
        TRIM( $username ),
        $password,
        $status,        # IN OUT
        $sessionid,     # IN OUT
        $USER,          # IN OUT
        $idtype         # IN OUT
    );

    IF NOT '' = TRIM( $apikey ) AND EXISTS( SELECT * FROM base_apikeys WHERE $apikey LIKE CONCAT( apikey, '%' ) ) THEN

        #
        #   Disable CSRF checks because is being called from
        #   a mobile (or other) device that does not need CSRF Token.
        #
        UPDATE base_users_sessions SET csrf='' WHERE sid = $sessionid;

    END IF;

    SELECT
        email,
        given_name,
        $status                        AS status,
        $sessionid                     AS sessionid,
        SUBSTRING( $sessionid, 1, 32 ) AS accessid,
        $idtype                        AS idtype,
        IFNULL( group_code, '' )       AS group_code

    FROM base_users
    LEFT JOIN base_groups_members USING (USER)
    LEFT JOIN base_groups         USING (GROUP_ID)
    WHERE USER = $USER;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Auth_OTC
(
    $mobile    TEXT,
    $email     TEXT,
    $deviceid  TEXT,
    $otc       TEXT,
    $generate  BOOL
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $count  INT  DEFAULT 0;

    SET $mobile   = TRIM( $mobile   );
    SET $deviceid = TRIM( $deviceid );
    SET $email    = TRIM( $email    );

    IF $generate THEN

        SET $otc = RandomNumber( 9999 ); # Create 4 number one-time-code.

        IF "" = $email THEN

            SELECT COUNT(*) INTO $count
            FROM   base_users
            WHERE  email = $mobile OR mobile = $mobile;

        END IF;

        IF $count > 1 THEN 

            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CONFIRM_EMAIL IN Auth_OTC';

        ELSE

            CALL Base_Users_Send_Resets_Replace_OTC( $mobile, $email, $otc );

        END IF;

    ELSE

        BEGIN

            DECLARE $username  TEXT  DEFAULT '';
            DECLARE $password  TEXT  DEFAULT '';

            SELECT email
            INTO  $username
            FROM   base_users
            WHERE  USER = Base_Users_Send_Resets_Get_User( $otc );

            SET $password = GenerateSalt();

            CALL Base_Users_Send_Resets_Reset_Password_OTC( $otc, $deviceid, $password );

            SELECT $username AS username, $password AS password;

        END;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Auth_Session
(
    $Sid  CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $Rid TEXT DEFAULT '';

    SET $Rid = Base_Users_Sessions_Resolve_Sid( $Sid );

    CALL Base_Users_Sessions_Extend_Expiry( $Rid );

    SELECT
        view_base_users.email,
        view_base_users.given_name,
        view_base_users.family_name,
        view_base_users.user_hash,
        view_base_users.type AS idtype,
        @@read_only          AS read_only

    FROM base_users_sessions
    LEFT JOIN view_base_users ON (AUTH_USER=USER)
    WHERE sid=$Rid
    LIMIT 1;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Auth_Access
(
    $apikey       TEXT,
    $server_name  CHAR(99),
    $remote_ip    CHAR(45),
    $Aid          CHAR(32)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $access                 TEXT  DEFAULT '';
    DECLARE $connection_csrf_token  TEXT  DEFAULT '';
    DECLARE $group_code             TEXT  DEFAULT '';
    DECLARE $idtype                 TEXT  DEFAULT '';
    DECLARE $keys                   TEXT  DEFAULT '';
    DECLARE $USER                   INT   DEFAULT  0;
    DECLARE $expiry                 INT   DEFAULT  0;

    IF "" != $apikey THEN

        BEGIN

            DECLARE $_apikey CHAR(64) DEFAULT '';

            SET $_apikey = SUBSTRING_INDEX( $apikey, "@", 1 );

            CALL Base_Web_Connections_Create_Out
            (
                $_apikey,
                $server_name,
                $remote_ip,
                $connection_csrf_token
            );

        END;

    END IF;

    IF "" != $Aid THEN

        SELECT  expiry,  AUTH_USER,  group_code
        INTO   $expiry,      $USER, $group_code
        FROM   base_users_sessions
        WHERE  SUBSTRING( sid, 1, 32 ) = $Aid;

    END IF;

    IF $USER AND UNIX_TIMESTAMP() < $expiry THEN

        SET $access = "PERMITTED";

        SELECT   type
        INTO  $idtype
        FROM   base_users_uids
        WHERE  USER = $USER;

        SET $keys = CONCAT_WS( '-', OrNull( $idtype ), OrNull( $group_code ) );

    ELSE

        SET $access = "DENIED";

    END IF;

    SELECT
        $access                AS access,
        $connection_csrf_token AS CSRF_Token,
        $keys                  AS Access_Keys;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Auth_Logout
(
    $Sid  CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $Rid TEXT DEFAULT '';

    CALL Base_Users_Sessions_Terminate( $Sid );

    SET $Rid = Base_Users_Sessions_Resolve_Sid( $Sid );

    CALL Base_Users_Sessions_Terminate( $Rid );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Accounts_Logout_All
(
    $Sid  CHAR(64)
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

DECLARE $AUTH_USER  INT  DEFAULT 0;

IF @@read_only THEN

    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

ELSE

    SELECT AUTH_USER INTO $AUTH_USER FROM base_users_sessions WHERE sid=$Sid LIMIT 1;

    DELETE FROM base_users_sessions WHERE AUTH_USER=$AUTH_USER AND NOT sid=$Sid;

END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Organisations
(
    $Sid       TEXT,
    $apikey    TEXT,
    $ORG_ID    INT,
    $org_name  TEXT,
    $limit     INT,
    $offset    INT,
    $order     TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL CheckLimitOffset( $limit, $offset );

    CALL Base_Users_Authorise_Sessionid_Or_Apikey( $Sid, $apikey, @email, @USER, @idtype );

    IF NOT ( @idtype LIKE '%USER%' OR @idtype LIKE '%ADMIN%' ) THEN 

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Organisations';

    ELSEIF "org_name" = $order OR "" = $order THEN

        SELECT    *
        FROM      base_organisations
        WHERE     0 = org_deleted
        AND      (0  = $ORG_ID   OR ORG_ID   = $ORG_ID  )
        AND      ('' = $org_name OR org_name = $org_name)
        AND      (@idtype = 'ADMIN' OR ORG_ID IN (SELECT ORG_ID FROM base_organisations_users WHERE ORG_USER_ID = @USER))
        ORDER BY  org_name
        LIMIT    $limit
        OFFSET   $offset;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Organisations_Replace
(
    $Sid       TEXT,
    $apikey    TEXT,
    $ORG_ID    INT,
    $org_name  TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid_Or_Apikey( $Sid, $apikey, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT ( @idtype LIKE '%USER%' OR @idtype LIKE '%ADMIN%' ) THEN 

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Organisations_Replace';

    ELSE

        IF NOT $ORG_ID THEN

            REPLACE INTO base_organisations
            (  ORG_ID )
            VALUES
            ( $ORG_ID );

            SET $ORG_ID = LAST_INSERT_ID();

            REPLACE INTO base_organisations_users
            (  ORG_ID,  ORG_USER_ID,  org_user_role )
            VALUES
            ( $ORG_ID,        @USER, 'OWNER.QUERY.REPLACE.SAVE.DELETE' );

        END IF;

        UPDATE base_organisations
        SET
            org_name = $org_name

        WHERE ORG_ID = $ORG_ID;

        DO LAST_INSERT_ID( $ORG_ID );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Organisations_Delete
(
    $Sid       TEXT,
    $apikey    TEXT,
    $ORG_ID    INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid_Or_Apikey( $Sid, $apikey, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT ( @idtype LIKE '%ADMIN%' ) THEN 

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Organisations_Delete';

    ELSE

        UPDATE base_organisations
        SET
            org_deleted = NOW()

        WHERE ORG_ID = $ORG_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Organisations_Users
(
    $Sid                              TEXT,
    $apikey                           TEXT,
    $ORG_ID                           INT,
    $ORG_USER_ID                      INT,
    $order                            TEXT,
    $limit                            INT,
    $offset                           INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL CheckLimitOffset( $limit, $offset );

    CALL Base_Users_Authorise_Sessionid_Or_Apikey_For_Org( $Sid, $apikey, $ORG_ID, @email, @USER, @idtype, @role );

    IF NOT( @idtype LIKE '%USER%' OR @idtype LIKE '%ADMIN%' ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Organisations_Users';

    ELSEIF NOT( @role LIKE '%SELECT%' ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_ROLE IN Base_Organisations_Users';

    ELSEIF 'org_user_role' = $order OR '' = $order THEN

        SELECT
            ORG_ID,
            ORG_USER_ID,
            org_user_role,
            given_name,
            family_name,
            email

        FROM      base_organisations_users
        LEFT JOIN base_users ON (ORG_USER_ID=USER)
        WHERE     ORG_ID                          = $ORG_ID
        AND       base_organisations_user_deleted = 0
        AND       (0  = $ORG_ID                         OR ORG_ID                          = $ORG_ID)
        AND       (0  = $ORG_USER_ID                    OR ORG_USER_ID                     = $ORG_USER_ID)
        ORDER BY  org_user_role
        LIMIT     $limit
        OFFSET    $offset;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Organisations_Users_Replace
(
    $Sid                              TEXT,
    $apikey                           TEXT,
    $ORG_ID                           INT,
    $USER                             INT,
    $org_user_role                    TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid_Or_Apikey_For_Org( $Sid, $apikey, $ORG_ID, @email, @USER, @idtype, @role );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT( @idtype LIKE '%USER%' OR @idtype LIKE '%ADMIN%' ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Organisations_Users_Replace';

    ELSEIF NOT( @role LIKE '%REPLACE%' ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_ROLE IN Base_Organisations_Users_Replace';

    ELSEIF NOT $USER THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Organisations_Users_Replace';

    ELSE

        IF NOT EXISTS( SELECT * FROM base_organisations_users WHERE ORG_ID=$ORG_ID AND ORG_USER_ID=$USER ) THEN

            REPLACE INTO base_organisations_users
            ( ORG_ID,  ORG_USER_ID)
            VALUES
            ($ORG_ID,        $USER);

        END IF;

        UPDATE base_organisations_users
        SET
            org_user_role = $org_user_role

        WHERE org_user_deleted = 0
        AND   ORG_ID           = $ORG_ID
        AND   ORG_USER_ID      = $USER;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Projects
(
    $Sid           TEXT,
    $PROJECT_ID    INT,
    $project_guid  TEXT,
    $order         TEXT,
    $limit         INT,
    $offset        INT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF NOT $PROJECT_ID AND NOT "" = $project_guid THEN
        SELECT PROJECT_ID INTO $PROJECT_ID
        FROM   base_projects
        WHERE  project_guid = $project_guid;
    END IF;

    SELECT    *
    FROM      base_projects
    LEFT JOIN base_organisations USING (ORG_ID)
    WHERE     PROJECT_ID IN
    (
        SELECT PROJECT_ID FROM base_projects_users
        WHERE  USER=@USER
        AND   (0 = $PROJECT_ID OR PROJECT_ID=$PROJECT_ID)
        AND   project_roles LIKE '%QUERY%'
    );

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Projects_Replace
(
    $Sid           TEXT,
    $ORG_ID        INT,
    $GROUP_ID      INT,
    $PROJECT_ID    INT,
    $project_guid  TEXT,
    $project_name  TEXT,
    $project_code  TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    IF NOT $PROJECT_ID AND NOT "" = $project_guid THEN
        SELECT PROJECT_ID INTO $PROJECT_ID
        FROM   base_projects
        WHERE  project_guid = $project_guid;
    END IF;

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT ( @idtype LIKE '%USER%' OR @idtype LIKE '%ADMIN%' ) THEN 

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Projects_Replace';

    ELSEIF $ORG_ID AND NOT EXISTS
    (
        SELECT *
        FROM   base_organisations_users
        LEFT JOIN base_organisations USING (ORG_ID)
        WHERE  org_user_deleted =    0
        AND    org_deleted      =    0
        AND    ORG_ID           =    $ORG_ID
        AND    ORG_USER_ID      =    @USER
        AND    org_user_role    LIKE '%REPLACE%'
    )
    THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Projects_Replace';

    ELSEIF $GROUP_ID AND NOT EXISTS
    (
        SELECT    *
        FROM      base_groups
        LEFT JOIN base_groups_members USING (GROUP_ID)
        WHERE
        (
            USER = @USER OR GROUP_OWNER = @USER
        )
    )
    THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_PARAMETERS IN Base_Projects_Replace';

    ELSE

        IF NOT $PROJECT_ID THEN

            REPLACE INTO base_projects
            (  ORG_ID,  GROUP_ID,  PROJECT_ID )
            VALUES
            ( $ORG_ID, $GROUP_ID, $PROJECT_ID );

            SET $PROJECT_ID = LAST_INSERT_ID();

            REPLACE INTO base_projects_users
            (  USER,  ORG_ID,  GROUP_ID,  PROJECT_ID,  project_roles                    )
            VALUES
            ( @USER, $ORG_ID, $GROUP_ID, $PROJECT_ID, 'OWNER.QUERY.REPLACE.SAVE.DELETE' );

        END IF;

        UPDATE base_projects
        SET
            project_name = $project_name,
            project_code = $project_code

        WHERE PROJECT_ID = $PROJECT_ID
        AND   @USER IN
        (
            SELECT USER FROM base_projects_users WHERE PROJECT_ID = $PROJECT_ID AND project_roles LIKE '%SAVE%'
        );

        DO LAST_INSERT_ID( $PROJECT_ID );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Selects_Base_Organisations
(
  $Sid                                   TEXT,
  $id                                    TEXT,
  $value                                 TEXT,
  $filter                                TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid( $Sid, @email, @USER, @idtype );

    SELECT
        ORG_ID   AS name,
        org_name AS text,
        $id      AS id,
        $value   AS value

    FROM      base_organisations
    LEFT JOIN base_organisations_users USING (ORG_ID)
    WHERE ORG_USER_ID = @USER
    AND   org_user_role LIKE '%query%';

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging
(
    $MESSAGE_ID                  INT,
    $order                       TEXT,
    $limit                       INT,
    $offset                      INT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    CALL CheckLimitOffset( $limit, $offset );

    IF 'message_created' = $order OR '' = $order THEN

        SELECT   *
        FROM     base_messaging
        WHERE    message_deleted = 0
        AND      (0  = $MESSAGE_ID                OR MESSAGE_ID                 = $MESSAGE_ID)
        ORDER BY message_created
        LIMIT    $limit
        OFFSET   $offset;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging_Replace
(
    $USER                        INT,
    $MESSAGE_ID                  INT,
    $message_guid                TEXT,
    $message_type                TEXT,
    $message_from                TEXT,
    $message_to                  TEXT,
    $message_cc                  TEXT,
    $message_bcc                 TEXT,
    $message_reply_to            TEXT,
    $message_subject             TEXT,
    $message_tags                TEXT,
    $message_content_txt64       LONGTEXT,
    $message_content_htm64       LONGTEXT,
    $message_send_at             DATETIME,
    $message_sent_at             DATETIME,
    $message_response_code       TEXT,
    $message_last_send_at        DATETIME,
    $message_last_sent_at        DATETIME,
    $message_last_response_code  TEXT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        IF NOT $MESSAGE_ID THEN

            REPLACE INTO base_messaging
            ( USER,  MESSAGE_ID)
            VALUES
            ($USER, $MESSAGE_ID);

            SET $MESSAGE_ID = LAST_INSERT_ID();

        END IF;

        UPDATE base_messaging
        SET
            message_guid               = $message_guid,
            message_type               = $message_type,
            message_from               = $message_from,
            message_to                 = $message_to,
            message_cc                 = $message_cc,
            message_bcc                = $message_bcc,
            message_reply_to           = $message_reply_to,
            message_subject            = $message_subject,
            message_tags               = $message_tags,
            message_content_txt64      = $message_content_txt64,
            message_content_htm64      = $message_content_htm64,
            message_send_at            = $message_send_at,
            message_sent_at            = $message_sent_at,
            message_response_code      = $message_response_code,
            message_last_send_at       = $message_last_send_at,
            message_last_sent_at       = $message_last_sent_at,
            message_last_response_code = $message_last_response_code

        WHERE message_deleted            = 0
        AND   MESSAGE_ID                 = $MESSAGE_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging_Save
(
    $MESSAGE_ID                INT,
    $name                      TEXT,
    $value                     TEXT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        CASE $name
        WHEN 'message_send_at'            THEN UPDATE base_messaging SET message_send_at            = $value WHERE MESSAGE_ID = MESSAGE_ID AND message_deleted = 0;
        WHEN 'message_sent_at'            THEN UPDATE base_messaging SET message_sent_at            = $value WHERE MESSAGE_ID = MESSAGE_ID AND message_deleted = 0;
        WHEN 'message_response_code'      THEN UPDATE base_messaging SET message_response_code      = $value WHERE MESSAGE_ID = MESSAGE_ID AND message_deleted = 0;
        WHEN 'message_last_send_at'       THEN UPDATE base_messaging SET message_last_send_at       = $value WHERE MESSAGE_ID = MESSAGE_ID AND message_deleted = 0;
        WHEN 'message_last_sent_at'       THEN UPDATE base_messaging SET message_last_sent_at       = $value WHERE MESSAGE_ID = MESSAGE_ID AND message_deleted = 0;
        WHEN 'message_last_response_code' THEN UPDATE base_messaging SET message_last_response_code = $value WHERE MESSAGE_ID = MESSAGE_ID AND message_deleted = 0;
        ELSE

            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_CASE_OPTION IN Base_messaging_Save';

        END CASE;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging_Delete
(
    $ID                        INT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        UPDATE base_messaging
        SET
            message_deleted = NOW()

        WHERE message_deleted            = 0
        AND   MESSAGE_ID                 = $MESSAGE_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging_Create
(
    $USER                        INT,
    $message_type                TEXT,
    $message_from                TEXT,
    $message_to                  TEXT,
    $message_cc                  TEXT,
    $message_bcc                 TEXT,
    $message_reply_to            TEXT,
    $message_subject             TEXT,
    $message_tags                TEXT,
    $message_content_txt64       LONGTEXT,
    $message_content_htm64       LONGTEXT,
    $message_send_at             TEXT
)
SQL SECURITY INVOKER
COMMENT 'GENERATED BY SPGEN.ORG'
BEGIN

    DECLARE $MESSAGE_ID    INT   DEFAULT  0;
    DECLARE $message_guid  TEXT  DEFAULT '';

    IF 'NOW' = $message_send_at THEN
        SET $message_send_at = NOW();
    END IF;

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSE

        REPLACE INTO base_messaging
        ( USER,  MESSAGE_ID)
        VALUES
        ($USER, $MESSAGE_ID);
        SET $MESSAGE_ID = LAST_INSERT_ID();

        CALL Base_Guids_Create( 'message', $MESSAGE_ID, $message_guid );

        UPDATE base_messaging
        SET
            message_guid               = $message_guid,
            message_type               = $message_type,
            message_from               = $message_from,
            message_to                 = $message_to,
            message_cc                 = $message_cc,
            message_bcc                = $message_bcc,
            message_reply_to           = $message_reply_to,
            message_subject            = $message_subject,
            message_tags               = $message_tags,
            message_content_txt64      = $message_content_txt64,
            message_content_htm64      = $message_content_htm64,
            message_send_at            = $message_send_at

        WHERE message_deleted          = 0
        AND   MESSAGE_ID               = $MESSAGE_ID;

        DO LAST_INSERT_ID( $MESSAGE_ID );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging_Sent
(
    $apikey         TEXT,
    $MESSAGE_ID     INT,
    $response_code  TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    CALL Base_Users_Authorise_Sessionid_Or_APIKey( '', $apikey, @email, @USER, @idtype );

    IF @@read_only THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'READ_ONLY';

    ELSEIF NOT( "ADMIN" = @idtype ) THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHRISATION IN Base_Messaging_Sent';

    ELSEIF EXISTS( SELECT * FROM base_messaging WHERE MESSAGE_ID=$MESSAGE_ID AND message_sent_at = 0 ) THEN

        UPDATE base_messaging
        SET
            message_sent_at       = NOW(),
            message_response_code = $response_code

        WHERE MESSAGE_ID = $MESSAGE_ID;

    ELSEIF EXISTS( SELECT * FROM base_messaging WHERE MESSAGE_ID=$MESSAGE_ID AND message_last_sent_at = 0 ) THEN

        UPDATE base_messaging
        SET
            message_last_sent_at       = NOW(),
            message_last_response_code = $response_code

        WHERE MESSAGE_ID = $MESSAGE_ID;

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE Base_Messaging_Unsent
(
    $apikey        TEXT,
    $message_type  TEXT
)
SQL SECURITY DEFINER
COMMENT 'EXPORT'
BEGIN

    DECLARE $MESSAGE_ID    INT   DEFAULT  0;
    DECLARE $message_guid  TEXT  DEFAULT '';

    CALL Base_Users_Authorise_Sessionid_Or_APIKey( '', $apikey, @email, @USER, @idtype );

    IF NOT "ADMIN" = @idtype THEN

        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_AUTHORISATION IN Base_Messaging_Unsent';

    ELSE

        SELECT *
        FROM   base_messaging
        WHERE  message_deleted = 0
        AND    message_type    = $message_type
        AND
        (
            (NOT 0 = message_send_at      AND message_send_at      < NOW() AND 0 = message_sent_at)
            OR
            (NOT 0 = message_last_send_at AND message_last_send_at < NOW() AND 0 = message_last_sent_at)
        );

    END IF;

END
//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE BaseTest()
SQL SECURITY INVOKER
BEGIN

IF NOT EXISTS( SELECT * FROM base_users ) THEN
CALL Base_Users_Create_Admin( 'Forgotten_password2020#' );
CALL Base_Users_Admin_Reset_Password( 'admin', 'Password2020#' );
CALL Base_Users_Sessions_Replace( 'admin', 'Password2020#' );
SELECT sid INTO @admin FROM base_users_sessions ORDER BY created DESC LIMIT 1; 
IF NOT Base_Users_Sessions_Verify( @admin ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ABANDONED AT #1';    
END IF;
CALL Base_APIKeys_Create( @admin );
SELECT apikey INTO @admin_apikey FROM base_apikeys ORDER BY APIKEY_ID DESC LIMIT 1;
CALL Base_Users_Sessions_Terminate( @admin );
CALL Base_Users_Create                ( 'mary@example.com', 'Password2020#', 'Mary', 'Swanson', 'USER' );
CALL Base_Users_Sessions_Replace_Inout( 'mary@example.com', 'Password2020#', @status, @mary, @MARY_ID, @mary_type );
CALL Base_Users_Create_Quietly        (  'tom@example.com', 'Password2020#', 'Tom', 'Bombadil', 'USER', FALSE );
CALL Base_Users_Sessions_Replace_Inout(  'tom@example.com', 'Password2020#', @status,  @tom,  @TOM_ID, @tom_type );
IF NOT Base_Users_Sessions_Verify( @mary ) OR NOT Base_Users_Sessions_Verify( @tom ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ABANDONED AT #2';
END IF;
CALL Base_Groups_Create( @mary, 'Group Mary', 'MARY' );
SET @GROUP_ID = LAST_INSERT_ID();
CALL Base_Groups_Members_Add( @mary, @GROUP_ID, @MARY_ID,  TRUE );

CALL Base_Groups_Members_Add( @mary, @GROUP_ID,  @TOM_ID, FALSE );
IF NOT Base_Groups_Members_Contains( @GROUP_ID, @MARY_ID ) OR NOT Base_Groups_Members_Contains( @GROUP_ID, @TOM_ID ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ABANDONED AT #3';
END IF;
CALL Base_Places_Create_Inout( @mary, '', '8 Navigator Place, Hendra, 4011',     '', @HENDRA_PLACE_ID );

CALL Base_Places_Create_Inout( @mary, '', '88 Norman Avenue, Norman Park, 4170', '', @NORMAN_PLACE_ID );
CALL Base_Places_Routes_Create( @mary, '', @HENDRA_PLACE_ID, @NORMAN_PLACE_ID, 0, 0 );
SET @ROUTE_ID = LAST_INSERT_ID();
CALL Base_Places_Routes_Save( @mary, '', @ROUTE_ID, 'route_distance_metres',  1000 );
CALL Base_Places_Routes_Save( @mary, '', @ROUTE_ID, 'route_duration_seconds', 1000 );
CALL Base_Places_Unprocessed( '', @admin_apikey );
END IF;

END
//
DELIMITER ;
