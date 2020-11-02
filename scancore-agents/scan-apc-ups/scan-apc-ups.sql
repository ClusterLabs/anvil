-- This is the database schema for the 'APC UPS Scan Agent'.

CREATE TABLE scan_apc_upses (
    scan_apc_ups_uuid                     uuid                        not null    primary key,
    scan_apc_ups_ups_uuid                 uuid                        not null,
    scan_apc_ups_serial_number            text                        not null,
    scan_apc_ups_name                     text                        not null,
    scan_apc_ups_ip                       text                        not null,
    scan_apc_ups_ac_restore_delay         numeric                     not null,
    scan_apc_ups_shutdown_delay           numeric                     not null,
    scan_apc_ups_firmware_version         text                        not null,
    scan_apc_ups_health                   numeric                     not null,
    scan_apc_ups_high_transfer_voltage    numeric                     not null,
    scan_apc_ups_low_transfer_voltage     numeric                     not null,
    scan_apc_ups_last_transfer_reason     numeric                     not null,
    scan_apc_ups_manufactured_date        text                        not null,
    scan_apc_ups_model                    text                        not null,
    scan_apc_ups_temperature_units        text                        not null,
    scan_apc_ups_nmc_firmware_version     text                        not null,
    scan_apc_ups_nmc_serial_number        text                        not null,
    scan_apc_ups_nmc_mac_address          text                        not null,
    modified_date                         timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_ups_ups_uuid) REFERENCES upses(ups_uuid)
);
ALTER TABLE scan_apc_upses OWNER TO admin;

CREATE TABLE history.scan_apc_upses (
    history_id                            bigserial,
    scan_apc_ups_uuid                     uuid,
    scan_apc_ups_ups_uuid                 uuid,
    scan_apc_ups_serial_number            text,
    scan_apc_ups_name                     text,
    scan_apc_ups_ip                       text,
    scan_apc_ups_ac_restore_delay         numeric,
    scan_apc_ups_shutdown_delay           numeric,
    scan_apc_ups_firmware_version         text,
    scan_apc_ups_health                   numeric,
    scan_apc_ups_high_transfer_voltage    numeric,
    scan_apc_ups_low_transfer_voltage     numeric,
    scan_apc_ups_last_transfer_reason     numeric,
    scan_apc_ups_manufactured_date        text,
    scan_apc_ups_model                    text,
    scan_apc_ups_temperature_units        text,
    scan_apc_ups_nmc_firmware_version     text,
    scan_apc_ups_nmc_serial_number        text,
    scan_apc_ups_nmc_mac_address          text,
    modified_date                         timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_upses OWNER TO admin;

CREATE FUNCTION history_scan_apc_upses() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_upses RECORD;
BEGIN
    SELECT INTO history_scan_apc_upses * FROM scan_apc_upses WHERE scan_apc_ups_uuid=new.scan_apc_ups_uuid;
    INSERT INTO history.scan_apc_upses
        (scan_apc_ups_uuid,
         scan_apc_ups_serial_number, 
         scan_apc_ups_name, 
         scan_apc_ups_ip, 
         scan_apc_ups_ac_restore_delay, 
         scan_apc_ups_shutdown_delay, 
         scan_apc_ups_firmware_version, 
         scan_apc_ups_health, 
         scan_apc_ups_high_transfer_voltage, 
         scan_apc_ups_low_transfer_voltage, 
         scan_apc_ups_last_transfer_reason, 
         scan_apc_ups_manufactured_date, 
         scan_apc_ups_model, 
         scan_apc_ups_temperature_units, 
         scan_apc_ups_nmc_firmware_version,
         scan_apc_ups_nmc_serial_number,
         scan_apc_ups_nmc_mac_address,
         modified_date)
    VALUES
        (history_scan_apc_ups.scan_apc_ups_uuid,
         history_scan_apc_ups.scan_apc_ups_serial_number, 
         history_scan_apc_ups.scan_apc_ups_name,
         history_scan_apc_ups.scan_apc_ups_ip,
         history_scan_apc_ups.scan_apc_ups_ac_restore_delay, 
         history_scan_apc_ups.scan_apc_ups_shutdown_delay, 
         history_scan_apc_ups.scan_apc_ups_firmware_version, 
         history_scan_apc_ups.scan_apc_ups_health, 
         history_scan_apc_ups.scan_apc_ups_high_transfer_voltage, 
         history_scan_apc_ups.scan_apc_ups_low_transfer_voltage, 
         history_scan_apc_ups.scan_apc_ups_last_transfer_reason, 
         history_scan_apc_ups.scan_apc_ups_manufactured_date, 
         history_scan_apc_ups.scan_apc_ups_model, 
         history_scan_apc_ups.scan_apc_ups_temperature_units, 
         history_scan_apc_ups.scan_apc_ups_nmc_firmware_version,
         history_scan_apc_ups.scan_apc_ups_nmc_serial_number,
         history_scan_apc_ups.scan_apc_ups_nmc_mac_address,
         history_scan_apc_ups.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_upses() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_upses
    AFTER INSERT OR UPDATE ON scan_apc_upses
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_upses();


-- Battery stuff
CREATE TABLE scan_apc_ups_batteries (
    scan_apc_ups_battery_uuid                     uuid                        not null    primary key,
    scan_apc_ups_battery_scan_apc_ups_uuid        uuid                        not null,
    scan_apc_ups_battery_number                   numeric                     not null,
    scan_apc_ups_battery_replacement_date         text                        not null,
    scan_apc_ups_battery_health                   numeric                     not null,
    scan_apc_ups_battery_model                    text                        not null,
    scan_apc_ups_battery_percentage_charge        numeric                     not null,
    scan_apc_ups_battery_last_replacement_date    text                        not null,
    scan_apc_ups_battery_state                    numeric                     not null,
    scan_apc_ups_battery_temperature              numeric                     not null,
    scan_apc_ups_battery_alarm_temperature        numeric                     not null,
    scan_apc_ups_battery_voltage                  numeric                     not null,
    modified_date                                 timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_ups_battery_scan_apc_ups_uuid) REFERENCES scan_apc_upses(scan_apc_ups_uuid)
);
ALTER TABLE scan_apc_ups_battery OWNER TO admin;

CREATE TABLE history.scan_apc_ups_batteries (
    history_id                                    bigserial,
    scan_apc_ups_battery_uuid                     uuid,
    scan_apc_ups_battery_scan_apc_ups_uuid        uuid,
    scan_apc_ups_battery_number                   numeric,
    scan_apc_ups_battery_replacement_date         text,
    scan_apc_ups_battery_health                   numeric,
    scan_apc_ups_battery_model                    text,
    scan_apc_ups_battery_percentage_charge        numeric,
    scan_apc_ups_battery_last_replacement_date    text,
    scan_apc_ups_battery_state                    numeric,
    scan_apc_ups_battery_temperature              numeric,
    scan_apc_ups_battery_alarm_temperature        numeric,
    scan_apc_ups_battery_voltage                  numeric,
    modified_date                                 timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_ups_batteries OWNER TO admin;

CREATE FUNCTION history_scan_apc_ups_batteries() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_ups_batteries RECORD;
BEGIN
    SELECT INTO history_scan_apc_ups_batteries * FROM scan_apc_ups_batteries WHERE scan_apc_ups_battery_uuid=new.scan_apc_ups_battery_uuid;
    INSERT INTO history.scan_apc_ups_batteries 
        (scan_apc_ups_battery_uuid,
         scan_apc_ups_battery_scan_apc_ups_uuid,
         scan_apc_ups_battery_number, 
         scan_apc_ups_battery_replacement_date,
         scan_apc_ups_battery_health,
         scan_apc_ups_battery_model,
         scan_apc_ups_battery_percentage_charge,
         scan_apc_ups_battery_last_replacement_date,
         scan_apc_ups_battery_state,
         scan_apc_ups_battery_temperature,
         scan_apc_ups_battery_alarm_temperature,
         scan_apc_ups_battery_voltage,
         modified_date)
    VALUES
        (history_scan_apc_ups_battery.scan_apc_ups_battery_uuid,
         history_scan_apc_ups_battery.scan_apc_ups_battery_scan_apc_ups_uuid,
         history_scan_apc_ups_battery.scan_apc_ups_battery_number, 
         history_scan_apc_ups_battery.scan_apc_ups_battery_replacement_date,
         history_scan_apc_ups_battery.scan_apc_ups_battery_health,
         history_scan_apc_ups_battery.scan_apc_ups_battery_model,
         history_scan_apc_ups_battery.scan_apc_ups_battery_percentage_charge,
         history_scan_apc_ups_battery.scan_apc_ups_battery_last_replacement_date,
         history_scan_apc_ups_battery.scan_apc_ups_battery_state,
         history_scan_apc_ups_battery.scan_apc_ups_battery_temperature,
         history_scan_apc_ups_battery.scan_apc_ups_battery_alarm_temperature,
         history_scan_apc_ups_battery.scan_apc_ups_battery_voltage,
         history_scan_apc_ups_battery.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_ups_batteries() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_ups_batteries 
    AFTER INSERT OR UPDATE ON scan_apc_ups_batteries 
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_ups_batteries();


-- Input power
CREATE TABLE scan_apc_ups_input (
    scan_apc_ups_input_uuid                        uuid                        not null    primary key,
    scan_apc_ups_input_scan_apc_ups_uuid           uuid                        not null,
    scan_apc_ups_input_frequency                   numeric                     not null,
    scan_apc_ups_input_sensitivity                 numeric                     not null,
    scan_apc_ups_input_voltage                     numeric                     not null,
    scan_apc_ups_input_1m_maximum_input_voltage    numeric                     not null,
    scan_apc_ups_input_1m_minimum_input_voltage    numeric                     not null, 
    modified_date                                  timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_ups_input_scan_apc_ups_uuid) REFERENCES scan_apc_upses(scan_apc_ups_uuid)
);
ALTER TABLE scan_apc_ups_input OWNER TO admin;

CREATE TABLE history.scan_apc_ups_input (
    history_id                                     bigserial,
    scan_apc_ups_input_uuid                        uuid,
    scan_apc_ups_input_scan_apc_ups_uuid           uuid,
    scan_apc_ups_input_frequency                   numeric,
    scan_apc_ups_input_sensitivity                 numeric,
    scan_apc_ups_input_voltage                     numeric,
    scan_apc_ups_input_1m_maximum_input_voltage    numeric,
    scan_apc_ups_input_1m_minimum_input_voltage    numeric
    modified_date                                  timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_ups_input OWNER TO admin;

CREATE FUNCTION history_scan_apc_ups_input() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_ups_input RECORD;
BEGIN
    SELECT INTO history_scan_apc_ups_input * FROM scan_apc_ups_input WHERE scan_apc_ups_input_uuid=new.scan_apc_ups_input_uuid;
    INSERT INTO history.scan_apc_ups_input
        (scan_apc_ups_input_uuid,
         scan_apc_ups_input_scan_apc_ups_uuid,
         scan_apc_ups_input_frequency, 
         scan_apc_ups_input_sensitivity, 
         scan_apc_ups_input_voltage, 
         scan_apc_ups_input_1m_maximum_input_voltage, 
         scan_apc_ups_input_1m_minimum_input_voltage, 
         modified_date)
    VALUES
        (history_scan_apc_ups_input.scan_apc_ups_input_uuid,
         history_scan_apc_ups_input.scan_apc_ups_input_scan_apc_ups_uuid,
         history_scan_apc_ups_input.scan_apc_ups_input_frequency, 
         history_scan_apc_ups_input.scan_apc_ups_input_sensitivity, 
         history_scan_apc_ups_input.scan_apc_ups_input_voltage, 
         history_scan_apc_ups_input.scan_apc_ups_input_1m_maximum_input_voltage, 
         history_scan_apc_ups_input.scan_apc_ups_input_1m_minimum_input_voltage, 
         history_scan_apc_ups_input.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_ups_input() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_ups_input
    AFTER INSERT OR UPDATE ON scan_apc_ups_input
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_ups_input();


-- Output power
CREATE TABLE scan_apc_ups_output (
    scan_apc_ups_output_uuid                 uuid                        not null    primary key,
    scan_apc_ups_output_scan_apc_ups_uuid    uuid                        not null,
    scan_apc_ups_output_load_percentage      numeric                     not null,
    scan_apc_ups_output_time_on_batteries    numeric                     not null,
    scan_apc_ups_output_estimated_runtime    numeric                     not null,
    scan_apc_ups_output_frequency            numeric                     not null,
    scan_apc_ups_output_voltage              numeric                     not null,
    scan_apc_ups_output_total_output         numeric                     not null,
    modified_date                            timestamp with time zone    not null,
    
    FOREIGN KEY(scan_apc_ups_output_scan_apc_ups_uuid) REFERENCES scan_apc_upses(scan_apc_ups_uuid)
);
ALTER TABLE scan_apc_ups_output OWNER TO admin;

CREATE TABLE history.scan_apc_ups_output (
    history_id                               bigserial,
    scan_apc_ups_output_uuid                 uuid,
    scan_apc_ups_output_scan_apc_ups_uuid    uuid,
    scan_apc_ups_output_load_percentage      numeric,
    scan_apc_ups_output_time_on_batteries    numeric,
    scan_apc_ups_output_estimated_runtime    numeric,
    scan_apc_ups_output_frequency            numeric,
    scan_apc_ups_output_voltage              numeric,
    scan_apc_ups_output_total_output         numeric,
    modified_date                            timestamp with time zone    not null
);
ALTER TABLE history.scan_apc_ups_output OWNER TO admin;

CREATE FUNCTION history_scan_apc_ups_output() RETURNS trigger
AS $$
DECLARE
    history_scan_apc_ups_output RECORD;
BEGIN
    SELECT INTO history_scan_apc_ups_output * FROM scan_apc_ups_output WHERE scan_apc_ups_output_uuid=new.scan_apc_ups_output_uuid;
    INSERT INTO history.scan_apc_ups_output
        (scan_apc_ups_output_uuid,
         scan_apc_ups_output_scan_apc_ups_uuid,
         scan_apc_ups_output_load_percentage, 
         scan_apc_ups_output_time_on_batteries, 
         scan_apc_ups_output_estimated_runtime, 
         scan_apc_ups_output_frequency, 
         scan_apc_ups_output_voltage, 
         scan_apc_ups_output_total_output, 
         modified_date)
    VALUES
        (history_scan_apc_ups_output.scan_apc_ups_output_uuid,
         history_scan_apc_ups_output.scan_apc_ups_output_scan_apc_ups_uuid,
         history_scan_apc_ups_output.scan_apc_ups_output_load_percentage, 
         history_scan_apc_ups_output.scan_apc_ups_output_time_on_batteries, 
         history_scan_apc_ups_output.scan_apc_ups_output_estimated_runtime, 
         history_scan_apc_ups_output.scan_apc_ups_output_frequency, 
         history_scan_apc_ups_output.scan_apc_ups_output_voltage, 
         history_scan_apc_ups_output.scan_apc_ups_output_total_output, 
         history_scan_apc_ups_output.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_apc_ups_output() OWNER TO admin;

CREATE TRIGGER trigger_scan_apc_ups_output
    AFTER INSERT OR UPDATE ON scan_apc_ups_output
    FOR EACH ROW EXECUTE PROCEDURE history_scan_apc_ups_output();
