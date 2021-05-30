-- This is the database schema for the 'scan-ipmitool' Scan Agent.

CREATE TABLE scan_ipmitool (
    scan_ipmitool_uuid                    uuid                        not null    primary key,
    scan_ipmitool_host_uuid               uuid                        not null,
    scan_ipmitool_sensor_host             text                        not null,                   -- The hostname of the machine we pulled the sensor value from. We don't link this to a host_uuid because it is possible the host doesn't doesn't have an entry (yet)
    scan_ipmitool_sensor_name             text                        not null,
    scan_ipmitool_sensor_units            text                        not null,                   -- Temperature (°C), vDC, vAC, watt, amp, percent
    scan_ipmitool_sensor_status           text                        not null,
    scan_ipmitool_sensor_high_critical    numeric                     not null,
    scan_ipmitool_sensor_high_warning     numeric                     not null,
    scan_ipmitool_sensor_low_critical     numeric                     not null,
    scan_ipmitool_sensor_low_warning      numeric                     not null,
    modified_date                         timestamp with time zone    not null,
    
    FOREIGN KEY(scan_ipmitool_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_ipmitool OWNER TO admin;

CREATE TABLE history.scan_ipmitool (
    history_id                            bigserial,
    scan_ipmitool_uuid                    uuid,
    scan_ipmitool_host_uuid               uuid,
    scan_ipmitool_sensor_host             text,
    scan_ipmitool_sensor_name             text,
    scan_ipmitool_sensor_units            text,
    scan_ipmitool_sensor_status           text,
    scan_ipmitool_sensor_high_critical    numeric,
    scan_ipmitool_sensor_high_warning     numeric,
    scan_ipmitool_sensor_low_critical     numeric,
    scan_ipmitool_sensor_low_warning      numeric,
    modified_date                         timestamp with time zone    not null
);
ALTER TABLE history.scan_ipmitool OWNER TO admin;

CREATE FUNCTION history_scan_ipmitool() RETURNS trigger
AS $$
DECLARE
    history_scan_ipmitool RECORD;
BEGIN
    SELECT INTO history_scan_ipmitool * FROM scan_ipmitool WHERE scan_ipmitool_uuid=new.scan_ipmitool_uuid;
    INSERT INTO history.scan_ipmitool
        (scan_ipmitool_uuid,
         scan_ipmitool_host_uuid, 
         scan_ipmitool_sensor_host, 
         scan_ipmitool_sensor_name, 
         scan_ipmitool_sensor_units, 
         scan_ipmitool_sensor_status, 
         scan_ipmitool_sensor_high_critical, 
         scan_ipmitool_sensor_high_warning, 
         scan_ipmitool_sensor_low_critical, 
         scan_ipmitool_sensor_low_warning, 
         modified_date)
    VALUES
        (history_scan_ipmitool.scan_ipmitool_uuid,
         history_scan_ipmitool.scan_ipmitool_host_uuid, 
         history_scan_ipmitool.scan_ipmitool_sensor_host, 
         history_scan_ipmitool.scan_ipmitool_sensor_name, 
         history_scan_ipmitool.scan_ipmitool_sensor_units, 
         history_scan_ipmitool.scan_ipmitool_sensor_status, 
         history_scan_ipmitool.scan_ipmitool_sensor_high_critical, 
         history_scan_ipmitool.scan_ipmitool_sensor_high_warning, 
         history_scan_ipmitool.scan_ipmitool_sensor_low_critical, 
         history_scan_ipmitool.scan_ipmitool_sensor_low_warning, 
         history_scan_ipmitool.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_ipmitool() OWNER TO admin;

CREATE TRIGGER trigger_scan_ipmitool
    AFTER INSERT OR UPDATE ON scan_ipmitool
    FOR EACH ROW EXECUTE PROCEDURE history_scan_ipmitool();


-- This contains the ever-changing sensor values. This is a separate table to keep the database as small as 
-- possible.
CREATE TABLE scan_ipmitool_values (
    scan_ipmitool_value_uuid                  uuid                        not null    primary key,
    scan_ipmitool_value_host_uuid             uuid                        not null,
    scan_ipmitool_value_scan_ipmitool_uuid    uuid                        not null,
    scan_ipmitool_value_sensor_value          numeric                     not null,
    modified_date                             timestamp with time zone    not null,
    
    FOREIGN KEY(scan_ipmitool_value_scan_ipmitool_uuid) REFERENCES scan_ipmitool(scan_ipmitool_uuid)
);
ALTER TABLE scan_ipmitool_values OWNER TO admin;

CREATE TABLE history.scan_ipmitool_values (
    history_id                                bigserial,
    scan_ipmitool_value_uuid                  uuid,
    scan_ipmitool_value_host_uuid             uuid,
    scan_ipmitool_value_scan_ipmitool_uuid    uuid,
    scan_ipmitool_value_sensor_value          numeric,
    modified_date                             timestamp with time zone    not null
);
ALTER TABLE history.scan_ipmitool_values OWNER TO admin;

CREATE FUNCTION history_scan_ipmitool_values() RETURNS trigger
AS $$
DECLARE
    history_scan_ipmitool_values RECORD;
BEGIN
    SELECT INTO history_scan_ipmitool_values * FROM scan_ipmitool_values WHERE scan_ipmitool_value_uuid=new.scan_ipmitool_value_uuid;
    INSERT INTO history.scan_ipmitool_values 
        (scan_ipmitool_value_uuid,
         scan_ipmitool_value_host_uuid, 
         scan_ipmitool_value_scan_ipmitool_uuid, 
         scan_ipmitool_value_sensor_value, 
         modified_date)
    VALUES
        (history_scan_ipmitool_values.scan_ipmitool_value_uuid,
         history_scan_ipmitool_values.scan_ipmitool_value_host_uuid, 
         history_scan_ipmitool_values.scan_ipmitool_value_scan_ipmitool_uuid, 
         history_scan_ipmitool_values.scan_ipmitool_value_sensor_value, 
         history_scan_ipmitool_values.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_ipmitool_values() OWNER TO admin;

CREATE TRIGGER trigger_scan_ipmitool_values
    AFTER INSERT OR UPDATE ON scan_ipmitool_values
    FOR EACH ROW EXECUTE PROCEDURE history_scan_ipmitool_values();
