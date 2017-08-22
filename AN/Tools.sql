-- This is the core database schema for AN::Tools. 
-- It expects PostgreSQL v. 9.1+

-- Table construction rules;
-- 
-- All tables need to have a column called '<table>_uuid  uuid  not null  primary key' that will have a 
-- unique UUID. This is used to keep track of the same entry in the history schema. If the table ends in a
-- plural, the '<table>_uuid' and can use the singular form of the table. For example, the table 'hosts' can
-- use 'host_uuid'.
-- 
-- All tables must hast a 'modified_date  timestamp with time zone  not null' column. This is used to track
-- changes through time in the history schema and used to groups changes when resync'ing.
-- 
-- Tables can optionally have a '*_host_uuid  uuid  not null' colum. If this is found, when resync'ing the
-- table, the resync will be restricted to the host's 'sys::host_uuid'.
-- 
-- Most tables will want to have a matching table in the history schema with an additional 
-- 'history_id  bigserial' column. Match the function and trigger seen elsewhere to copy your data from the
-- public schema to the history schema on UPDATE or INSERT.


SET client_encoding = 'UTF8';
-- This doesn't work before 9.3 - CREATE SCHEMA IF NOT EXISTS history;
-- So we'll use the query below until (if) we upgrade.
DO $$
BEGIN
	IF NOT EXISTS(
		SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'history'
	)
	THEN
		EXECUTE 'CREATE SCHEMA history';
	END IF;
END
$$;

-- This stores information about the host machine. This is the master table that everything will be linked 
-- to. 
CREATE TABLE hosts (
	host_uuid			uuid				not null	primary key,	-- This is the single most important record in ScanCore. Everything links back to here.
	host_name			text				not null,
	host_type			text				not null,			-- Either 'node' or 'dashboard'.
	modified_date			timestamp with time zone	not null
);
ALTER TABLE hosts OWNER TO #!variable!user!#;

CREATE TABLE history.hosts (
	history_id			bigserial,
	host_uuid			uuid				not null,
	host_name			text				not null,
	host_type			text				not null,
	modified_date			timestamp with time zone	not null
);
ALTER TABLE history.hosts OWNER TO #!variable!user!#;

CREATE FUNCTION history_hosts() RETURNS trigger
AS $$
DECLARE
	history_hosts RECORD;
BEGIN
	SELECT INTO history_hosts * FROM hosts WHERE host_uuid = new.host_uuid;
	INSERT INTO history.hosts
		(host_uuid,
		 host_name,
		 host_type,
		 modified_date)
	VALUES
		(history_hosts.host_uuid,
		 history_hosts.host_name,
		 history_hosts.host_type,
		 history_hosts.modified_date);
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_hosts() OWNER TO #!variable!user!#;

CREATE TRIGGER trigger_hosts
	AFTER INSERT OR UPDATE ON hosts
	FOR EACH ROW EXECUTE PROCEDURE history_hosts();


-- This stores special variables for a given host that programs may want to record.
CREATE TABLE host_variable (
	host_variable_uuid		uuid				not null	primary key,	-- This is the single most important record in ScanCore. Everything links back to here.
	host_variable_host_uuid		uuid				not null,
	host_variable_name		text				not null,
	host_variable_value		text,
	modified_date			timestamp with time zone	not null
);
ALTER TABLE host_variable OWNER TO #!variable!user!#;

CREATE TABLE history.host_variable (
	history_id			bigserial,
	host_variable_uuid		uuid				not null,
	host_variable_host_uuid		uuid,
	host_variable_name		text,
	host_variable_value		text,
	modified_date			timestamp with time zone	not null
);
ALTER TABLE history.host_variable OWNER TO #!variable!user!#;

CREATE FUNCTION history_host_variable() RETURNS trigger
AS $$
DECLARE
	history_host_variable RECORD;
BEGIN
	SELECT INTO history_host_variable * FROM host_variable WHERE host_uuid = new.host_uuid;
	INSERT INTO history.host_variable
		(host_variable_uuid,
		 host_variable_host_uuid, 
		 host_variable_name, 
		 host_variable_value, 
		 modified_date)
	VALUES
		(host_variable_uuid,
		 host_variable_host_uuid, 
		 host_variable_name, 
		 host_variable_value,
		 history_host_variable.modified_date);
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_host_variable() OWNER TO #!variable!user!#;

CREATE TRIGGER trigger_host_variable
	AFTER INSERT OR UPDATE ON host_variable
	FOR EACH ROW EXECUTE PROCEDURE history_host_variable();


-- This stores alerts coming in from various sources
CREATE TABLE alerts (
	alert_uuid		uuid				primary key,
	alert_host_uuid		uuid				not null,			-- The name of the node or dashboard that this alert came from.
	alert_set_by		text				not null,
	alert_level		text				not null,			-- debug (log only), info (+ admin email), notice (+ curious users), warning (+ client technical staff), critical (+ all)
	alert_title_key		text				not null,			-- ScanCore will read in the agents <name>.xml words file and look for this message key
	alert_title_variables	text,								-- List of variables to substitute into the message key. Format is 'var1=val1 #!# var2 #!# val2 #!# ... #!# varN=valN'.
	alert_message_key	text				not null,			-- ScanCore will read in the agents <name>.xml words file and look for this message key
	alert_message_variables	text,								-- List of variables to substitute into the message key. Format is 'var1=val1 #!# var2 #!# val2 #!# ... #!# varN=valN'.
	alert_sort		text,								-- The alerts will sort on this column. It allows for an optional sorting of the messages in the alert.
	alert_header		boolean				not null	default TRUE,	-- This can be set to have the alert be printed with only the contents of the string, no headers.
	modified_date		timestamp with time zone	not null,
	
	FOREIGN KEY(alert_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE alerts OWNER TO #!variable!user!#;

CREATE TABLE history.alerts (
	history_id		bigserial,
	alert_uuid		uuid,
	alert_host_uuid		uuid,
	alert_set_by		text,
	alert_level		text,
	alert_title_key		text,
	alert_title_variables	text,
	alert_message_key	text,
	alert_message_variables	text,
	alert_sort		text,
	alert_header		boolean,
	modified_date		timestamp with time zone	not null
);
ALTER TABLE history.alerts OWNER TO #!variable!user!#;

CREATE FUNCTION history_alerts() RETURNS trigger
AS $$
DECLARE
	history_alerts RECORD;
BEGIN
	SELECT INTO history_alerts * FROM alerts WHERE alert_uuid = new.alert_uuid;
	INSERT INTO history.alerts
		(alert_uuid,
		 alert_host_uuid,
		 alert_set_by,
		 alert_level,
		 alert_title_key,
		 alert_title_variables,
		 alert_message_key,
		 alert_message_variables,
		 alert_sort, 
		 alert_header, 
		 modified_date)
	VALUES
		(history_alerts.alert_uuid,
		 history_alerts.alert_host_uuid,
		 history_alerts.alert_set_by,
		 history_alerts.alert_level,
		 history_alerts.alert_title_key,
		 history_alerts.alert_title_variables,
		 history_alerts.alert_message_key,
		 history_alerts.alert_message_variables,
		 history_alerts.alert_sort, 
		 history_alerts.alert_header, 
		 history_alerts.modified_date);
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_alerts() OWNER TO #!variable!user!#;

CREATE TRIGGER trigger_alerts
	AFTER INSERT OR UPDATE ON alerts
	FOR EACH ROW EXECUTE PROCEDURE history_alerts();


-- This holds user-configurable variable. These values override defaults but NOT configuration files.
CREATE TABLE variables (
	variable_uuid			uuid				not null	primary key,	-- 
	variable_name			text				not null,			-- This is the 'x::y::z' style variable name.
	variable_value			text,								-- It is up to the software to sanity check variable values before they are stored
	variable_default		text,								-- This acts as a reference for the user should they want to roll-back changes.
	variable_description		text,								-- This is a string key that describes this variable's use.
	variable_section		text,								-- This is a free-form field that is used when displaying the various entries to a user. This allows for the various variables to be grouped into sections.
	variable_source_uuid		text,								-- Optional; Marks the variable as belonging to a specific X_uuid, where 'X' is a table name set in 'variable_source_table'
	variable_source_table		text,								-- Optional; Marks the database table corresponding to the 'variable_source_uuid' value.
	modified_date			timestamp with time zone	not null 
);
ALTER TABLE variables OWNER TO #!variable!user!#;

CREATE TABLE history.variables (
	history_id			bigserial,
	variable_uuid			uuid,
	variable_name			text,
	variable_value			text,
	variable_default		text,
	variable_description		text,
	variable_section		text,
	variable_source_uuid		text,
	variable_source_table		text,
	modified_date			timestamp with time zone	not null 
);
ALTER TABLE history.variables OWNER TO #!variable!user!#;

CREATE FUNCTION history_variables() RETURNS trigger
AS $$
DECLARE
	history_variables RECORD;
BEGIN
	SELECT INTO history_variables * FROM variables WHERE variable_uuid = new.variable_uuid;
	INSERT INTO history.variables
		(variable_uuid,
		 variable_name, 
		 variable_value, 
		 variable_default, 
		 variable_description, 
		 variable_section, 
		 variable_source_uuid, 
		 variable_source_table, 
		 modified_date)
	VALUES
		(history_variables.variable_uuid,
		 history_variables.variable_name, 
		 history_variables.variable_value, 
		 history_variables.variable_default, 
		 history_variables.variable_description, 
		 history_variables.variable_section, 
		 history_variables.variable_source_uuid, 
		 history_variables.variable_source_table, 
		 history_variables.modified_date);
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_variables() OWNER TO #!variable!user!#;

CREATE TRIGGER trigger_variables
	AFTER INSERT OR UPDATE ON variables
	FOR EACH ROW EXECUTE PROCEDURE history_variables();


-- ------------------------------------------------------------------------------------------------------- --
-- These are special tables with no history or tracking UUIDs that simply record transient information.    --
-- ------------------------------------------------------------------------------------------------------- --


-- This table records the last time a scan ran. It's sole purpose is to make sure at least one table's
-- 'modified_date' changes per run, so that database resyncs can be triggered reliably.
CREATE TABLE updated (
	updated_host_uuid	uuid				not null,
	updated_by		text				not null,			-- The name of the agent (or "ScanCore' itself) that updated.
	modified_date		timestamp with time zone	not null,
	
	FOREIGN KEY(updated_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE updated OWNER TO #!variable!user!#;


-- To avoid "waffling" when a sensor is close to an alert (or cleared) threshold, a gap between the alarm 
-- value and the clear value is used. If the sensor climbs above (or below) the "clear" value, but didn't 
-- previously pass the "alert" threshold, we DON'T want to send an "all clear" message. So do solve that, 
-- this table is used by agents to record when a warning message was sent. 
CREATE TABLE alert_sent (
	alert_sent_uuid		uuid				primary key,
	alert_sent_host_uuid	uuid				not null,			-- The node associated with this alert
	alert_set_by		text				not null,			-- name of the program that set this alert
	alert_record_locator	text				not null,			-- String used by the agent to identify the source of the alert (ie: UPS serial number)
	alert_name		text				not null,			-- A free-form name used by the caller to identify this alert.
	modified_date		timestamp with time zone	not null,
	
	FOREIGN KEY(alert_sent_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE updated OWNER TO #!variable!user!#;


-- This stores state information, like the whether migrations are happening and so on.
CREATE TABLE states (
	state_uuid		uuid				primary key,
	state_name		text				not null,			-- This is the name of the state (ie: 'migration', etc)
	state_host_uuid		uuid				not null,			-- The UUID of the machine that the state relates to. In migrations, this is the UUID of the target
	state_note		text,								-- This is a free-form note section that the application setting the state can use for extra information (like the name of the server being migrated)
	modified_date		timestamp with time zone	not null,
	
	FOREIGN KEY(state_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE states OWNER TO #!variable!user!#;
